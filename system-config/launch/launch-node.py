#!/usr/bin/env python

# Launch a new OpenStack project infrastructure node.

# Copyright (C) 2011-2012 OpenStack LLC.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
#
# See the License for the specific language governing permissions and
# limitations under the License.

import sys
import os
import time
import traceback
import argparse

import dns
import utils

NOVA_USERNAME = os.environ['OS_USERNAME']
NOVA_PASSWORD = os.environ['OS_PASSWORD']
NOVA_URL = os.environ['OS_AUTH_URL']
NOVA_PROJECT_ID = os.environ['OS_TENANT_NAME']
NOVA_REGION_NAME = os.environ['OS_REGION_NAME']
NOVA_SERVICE_NAME = os.environ.get('OS_SERVICE_NAME')
NOVACLIENT_INSECURE = os.getenv('NOVACLIENT_INSECURE', None)
IPV6 = os.environ.get('IPV6', '0') is 1

SCRIPT_DIR = os.path.dirname(sys.argv[0])


def get_client():
    args = [NOVA_USERNAME, NOVA_PASSWORD, NOVA_PROJECT_ID, NOVA_URL]
    kwargs = {}
    kwargs['region_name'] = NOVA_REGION_NAME
    kwargs['service_type'] = 'compute'
    if NOVA_SERVICE_NAME:
        kwargs['service_name'] = NOVA_SERVICE_NAME

    if NOVACLIENT_INSECURE:
        kwargs['insecure'] = True

    from novaclient.v1_1.client import Client
    client = Client(*args, **kwargs)
    return client


def bootstrap_server(server, admin_pass, key, cert, environment, name,
                     puppetmaster, volume, floating_ip_pool):
    ip = utils.get_public_ip(server, floating_ip_pool=floating_ip_pool)
    if not ip:
        raise Exception("Unable to find public ip of server")

    ssh_kwargs = {}
    if key:
        ssh_kwargs['pkey'] = key
    else:
        ssh_kwargs['password'] = admin_pass

    for username in ['root', 'ubuntu', 'centos', 'admin']:
        ssh_client = utils.ssh_connect(ip, username, ssh_kwargs, timeout=600)
        if ssh_client:
            break

    if not ssh_client:
        raise Exception("Unable to log in via SSH")

    # cloud-init puts the "please log in as user foo" message and
    # subsequent exit() in root's authorized_keys -- overwrite it with
    # a normal version to get root login working again.
    if username != 'root':
        ssh_client.ssh("sudo cp ~/.ssh/authorized_keys"
                       " ~root/.ssh/authorized_keys")
        ssh_client.ssh("sudo chmod 644 ~root/.ssh/authorized_keys")
        ssh_client.ssh("sudo chown root.root ~root/.ssh/authorized_keys")

    ssh_client = utils.ssh_connect(ip, 'root', ssh_kwargs, timeout=600)

    if IPV6:
        ssh_client.ssh('ping6 -c5 -Q 0x10 review.openstack.org '
                       '|| ping6 -c5 -Q 0x10 wiki.openstack.org')

    ssh_client.scp(os.path.join(SCRIPT_DIR, '..', 'make_swap.sh'),
                   'make_swap.sh')
    ssh_client.ssh('bash -x make_swap.sh')

    if volume:
        ssh_client.scp(os.path.join(SCRIPT_DIR, '..', 'mount_volume.sh'),
                       'mount_volume.sh')
        ssh_client.ssh('bash -x mount_volume.sh')

    ssh_client.scp(os.path.join(SCRIPT_DIR, '..', 'install_puppet.sh'),
                   'install_puppet.sh')
    ssh_client.ssh('bash -x install_puppet.sh')

    certname = cert[:(0 - len('.pem'))]
    ssh_client.ssh("mkdir -p /var/lib/puppet/ssl/certs")
    ssh_client.ssh("mkdir -p /var/lib/puppet/ssl/private_keys")
    ssh_client.ssh("mkdir -p /var/lib/puppet/ssl/public_keys")
    ssh_client.ssh("chown -R puppet:root /var/lib/puppet/ssl")
    ssh_client.ssh("chown -R puppet:puppet /var/lib/puppet/ssl/private_keys")
    ssh_client.ssh("chmod 0771 /var/lib/puppet/ssl")
    ssh_client.ssh("chmod 0755 /var/lib/puppet/ssl/certs")
    ssh_client.ssh("chmod 0750 /var/lib/puppet/ssl/private_keys")
    ssh_client.ssh("chmod 0755 /var/lib/puppet/ssl/public_keys")

    for ssldir in ['/var/lib/puppet/ssl/certs/',
                   '/var/lib/puppet/ssl/private_keys/',
                   '/var/lib/puppet/ssl/public_keys/']:
        ssh_client.scp(os.path.join(ssldir, cert),
                       os.path.join(ssldir, cert))

    ssh_client.scp("/var/lib/puppet/ssl/crl.pem",
                   "/var/lib/puppet/ssl/crl.pem")
    ssh_client.scp("/var/lib/puppet/ssl/certs/ca.pem",
                   "/var/lib/puppet/ssl/certs/ca.pem")

    (rc, output) = ssh_client.ssh(
        "puppet agent "
        "--environment %s "
        "--server %s "
        "--detailed-exitcodes "
        "--no-daemonize --verbose --onetime --pluginsync true "
        "--certname %s" % (environment, puppetmaster, certname), error_ok=True)
    utils.interpret_puppet_exitcodes(rc, output)

    try:
        ssh_client.ssh("reboot")
    except Exception as e:
        # Some init system kill the connection too fast after reboot.
        # Deal with it by ignoring ssh errors when rebooting.
        if e.rc == -1:
            pass
        else:
            raise


def build_server(
        client, name, image, flavor, cert, environment, puppetmaster, volume,
        keep, net_label, floating_ip_pool, boot_from_volume):
    key = None
    server = None

    create_kwargs = dict(image=image, flavor=flavor, name=name)

    if boot_from_volume:
        block_mapping = [{
            'boot_index': '0',
            'delete_on_termination': True,
            'destination_type': 'volume',
            'uuid': image.id,
            'source_type': 'image',
            'volume_size': '50',
        }]
        create_kwargs['image'] = None
        create_kwargs['block_device_mapping_v2'] = block_mapping

    if net_label:
        nics = []
        for net in client.networks.list():
            if net.label == net_label:
                nics.append({'net-id': net.id})
        create_kwargs['nics'] = nics

    key_name = 'launch-%i' % (time.time())
    if 'os-keypairs' in utils.get_extensions(client):
        print "Adding keypair"
        key, kp = utils.add_keypair(client, key_name)
        create_kwargs['key_name'] = key_name

    try:
        server = client.servers.create(**create_kwargs)
    except Exception:
        try:
            kp.delete()
        except Exception:
            print "Exception encountered deleting keypair:"
            traceback.print_exc()
        raise

    try:
        admin_pass = server.adminPass
        server = utils.wait_for_resource(server)
        if volume:
            vobj = client.volumes.create_server_volume(
                server.id, volume, None)
            if not vobj:
                raise Exception("Couldn't attach volume")

        bootstrap_server(server, admin_pass, key, cert, environment, name,
                         puppetmaster, volume, floating_ip_pool)
        print('UUID=%s\nIPV4=%s\nIPV6=%s\n' % (server.id,
                                               server.accessIPv4,
                                               server.accessIPv6))
        if key:
            kp.delete()
    except Exception:
        try:
            if keep:
                print "Server failed to build, keeping as requested."
            else:
                utils.delete_server(server)
        except Exception:
            print "Exception encountered deleting server:"
            traceback.print_exc()
        # Raise the important exception that started this
        raise


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("name", help="server name")
    parser.add_argument("--flavor", dest="flavor", default='1GB',
                        help="name (or substring) of flavor")
    parser.add_argument("--image", dest="image",
                        default="Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)",
                        help="image name")
    parser.add_argument("--environment", dest="environment",
                        default="production",
                        help="puppet environment name")
    parser.add_argument("--cert", dest="cert",
                        help="name of signed puppet certificate file (e.g., "
                        "hostname.example.com.pem)")
    parser.add_argument("--server", dest="server", help="Puppetmaster to use.",
                        default="puppetmaster.openstack.org")
    parser.add_argument("--volume", dest="volume",
                        help="UUID of volume to attach to the new server.",
                        default=None)
    parser.add_argument("--boot-from-volume", dest="boot_from_volume",
                        help="Create a boot volume for the server and use it.",
                        action='store_true',
                        default=False)
    parser.add_argument("--keep", dest="keep",
                        help="Don't clean up or delete the server on error.",
                        action='store_true',
                        default=False)
    parser.add_argument("--net-label", dest="net_label", default='',
                        help="network label to attach instance to")
    parser.add_argument("--fip-pool", dest="floating_ip_pool", default=None,
                        help="pool to assign floating IP from")
    options = parser.parse_args()

    client = get_client()

    if options.cert:
        cert = options.cert
    else:
        cert = options.name + ".pem"

    if not os.path.exists(os.path.join("/var/lib/puppet/ssl/private_keys",
                                       cert)):
        raise Exception("Please specify the name of a signed puppet cert.")

    flavors = [f for f in client.flavors.list()
               if options.flavor in (f.name, f.id)]
    flavor = flavors[0]
    print "Found flavor", flavor

    images = [i for i in client.images.list()
              if (options.image.lower() in (i.id, i.name.lower()) and
                  not i.name.endswith('(Kernel)') and
                  not i.name.endswith('(Ramdisk)'))]

    if len(images) > 1:
        print "Ambiguous image name; matches:"
        for i in images:
            print i.name
        sys.exit(1)

    if len(images) == 0:
        print "Unable to find matching image; image list:"
        for i in client.images.list():
            print i.name
        sys.exit(1)

    image = images[0]
    print "Found image", image

    if options.volume:
        print "The --volume option does not support cinder; until it does"
        print "it should not be used."
        sys.exit(1)

    build_server(client, options.name, image, flavor, cert,
                 options.environment, options.server, options.volume,
                 options.keep, options.net_label, options.floating_ip_pool,
                 options.boot_from_volume)
    dns.print_dns(client, options.name)
    # Remove the ansible inventory cache so that next run finds the new
    # server
    if os.path.exists('/var/cache/ansible-inventory/ansible-inventory.cache'):
        os.unlink('/var/cache/ansible-inventory/ansible-inventory.cache')
    os.system('/usr/local/bin/expand-groups.sh')

if __name__ == '__main__':
    main()
