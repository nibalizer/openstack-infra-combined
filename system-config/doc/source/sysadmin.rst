:title: System Administration

.. _sysadmin:

System Administration
#####################

Our infrastructure is code and contributions to it are handled just
like the rest of OpenStack.  This means that anyone can contribute to
the installation and long-running maintenance of systems without shell
access, and anyone who is interested can provide feedback and
collaborate on code reviews.

The configuration of every system operated by the infrastructure team
is managed by Puppet in a single Git repository:

  https://git.openstack.org/cgit/openstack-infra/system-config

All system configuration should be encoded in that repository so that
anyone may propose a change in the running configuration to Gerrit.

Making a Change in Puppet
=========================

Many changes to the Puppet configuration can safely be made while only
performing syntax checks.  Some more complicated changes merit local
testing and an interactive development cycle.  The system-config repo
is structured to facilitate local testing before proposing a change
for review.  This is accomplished by separating the puppet
configuration into several layers with increasing specificity about
site configuration higher in the stack.

The `modules/` directory holds puppet modules that abstractly describe
the configuration of a service.  Ideally, these should have no
OpenStack-specific information in them, and eventually they should all
become modules that are directly consumed from PuppetForge, only
existing in the system-config repo during an initial incubation period.
This is not yet the case, so you may find OpenStack-specific
configuration in these modules, though we are working to reduce it.

The `modules/openstack_project/manifests/` directory holds
configuration for each of the servers that the OpenStack project runs.
Think of these manifests as describing how OpenStack runs a particular
service.  However, no site-specific configuration such as hostnames or
credentials should be included in these files.  This is what lets you
easily test an OpenStack project manifest on your own server.

Finally, the `manifests/site.pp` file contains the information that is
specific to the actual servers that OpenStack runs.  These should be
very simple node definitions that largely exist simply to provide
private date from hiera to the more robust manifests in the
`openstack_project` modules.

This means that you can run the same configuration on your own server
simply by providing a different manifest file instead of site.pp.

.. note::
   The example below is for Debian / Ubuntu systems.  If you are using a
   RedHat based system be sure to setup sudo or simply run the commands as
   the root user.

As an example, to run the etherpad configuration on your own server,
start by ensuring git is installed and then cloning the system-config
Git repo::

  sudo su -
  apt-get install git
  git clone https://git.openstack.org/openstack-infra/system-config
  cd system-config

Then copy the etherpad node definition from manifests/site.pp to a new
file (be sure to specify the FQDN of the host you are working with in
the node specifier).  It might look something like this::

  # local.pp
  class { 'openstack_project::etherpad':
    ssl_cert_file_contents  => hiera('etherpad_ssl_cert_file_contents'),
    ssl_key_file_contents   => hiera('etherpad_ssl_key_file_contents'),
    ssl_chain_file_contents => hiera('etherpad_ssl_chain_file_contents'),
    mysql_host              => hiera('etherpad_db_host', 'localhost'),
    mysql_user              => hiera('etherpad_db_user', 'username'),
    mysql_password          => hiera('etherpad_db_password'),
  }

.. note::
   Be sure not to use any of the hiera functionality from manifests/site.pp
   since it is not installed yet. You should be able to comment out the logic
   safely.

Then to apply that configuration, run the following from the root of the
system-config repository::

  ./install_puppet.sh
  ./install_modules.sh
  puppet apply -l /tmp/manifest.log --modulepath=modules:/etc/puppet/modules manifests/local.pp

That should turn the system you are logged into into an etherpad
server with the same configuration as that used by the OpenStack
project. You can edit the contents of the system-config repo and
iterate ``puppet apply`` as needed. When you're ready to propose the
change for review, you can propose the change with git-review. See the
`Development workflow section in the Developer's Guide
<http://docs.openstack.org/infra/manual/developers.html#development-workflow>`_
for more information.

Adding a New Server
===================

To create a new server, do the following:

 * Add a file in :file:`modules/openstack_project/manifests/` that defines a
   class which specifies the configuration of the server.

 * Add a node entry in :file:`manifests/site.pp` for the server that uses that
   class.

 * If your server needs private information such as passwords, use
   hiera calls in the site manifest, and ask an infra-core team member
   to manually add the private information to hiera.

 * You should be able to install and configure most software only with
   puppet.  Nonetheless, if you need SSH access to the host, add your
   public key to :file:`modules/openstack_project/manifests/users.pp` and
   include a stanza like this in your server class::

     realize (
        User::Virtual::Localuser['USERNAME'],
     )

 * Add an RST file with documentation about the server in :file:`doc/source`
   and add it to the index in that directory.

SSH Access
==========

For any of the systems managed by the OpenStack Infrastructure team, the
following practices must be observed for SSH access:

 * SSH access is only permitted with SSH public/private key
   authentication.
 * Users must use a strong passphrase to protect their private key.  A
   passphrase of several words, at least one of which is not in a
   dictionary is advised, or a random string of at least 16
   characters.
 * To mitigate the inconvenience of using a long passphrase, users may
   want to use an SSH agent so that the passphrase is only requested
   once per desktop session.
 * Users private keys must never be stored anywhere except their own
   workstation(s).  In particular, they must never be stored on any
   remote server.
 * If users need to 'hop' from a server or bastion host to another
   machine, they must not copy a private key to the intermediate
   machine (see above).  Instead SSH agent forwarding may be used.
   However due to the potential for a compromised intermediate machine
   to ask the agent to sign requests without the users knowledge, in
   this case only an SSH agent that interactively prompts the user
   each time a signing request (ie, ssh-agent, but not gnome-keyring)
   is received should be used, and the SSH keys should be added with
   the confirmation constraint ('ssh-add -c').
 * The number of SSH keys that are configured to permit access to
   OpenStack machines should be kept to a minimum.
 * OpenStack Infrastructure machines must use puppet to centrally manage and
   configure user accounts, and the SSH authorized_keys files from the
   openstack-infra/system-config repository.
 * SSH keys should be periodically rotated (at least once per year).
   During rotation, a new key can be added to puppet for a time, and
   then the old one removed.  Be sure to run puppet on the backup
   servers to make sure they are updated.


GitHub Access
=============

To ensure that code review and testing are not bypassed in the public
Git repositories, only Gerrit will be permitted to commit code to
OpenStack repositories.  Because GitHub always allows project
administrators to commit code, accounts that have access to manage the
GitHub projects necessarily will have commit access to the
repositories.  Therefore, to avoid inadvertent commits to the public
repositories, unique administrative-only accounts must be used to
manage the OpenStack GitHub organization and projects.  These accounts
will not be used to check out or commit code for any project.

Root only information
#####################

Some information is only relevant if you have root access to the system - e.g.
you are an OpenStack CI root operator, or you are running a clone of the
OpenStack CI infrastructure for another project.

Backups
=======

Off-site backups are made to two servers:

 * ci-backup-rs-ord.openstack.org
 * TBD

Puppet is used to perform the initial configuration of those machines,
but to protect them from unauthorized access in case access to the
puppet git repo is compromised, it is not run in agent or in cron mode
on them.  Instead, it should be manually run when changes are made
that should be applied to the backup servers.

To start backing up a server, some commands need to be run manually on
both the backup server, and the server to be backed up.  On the server
to be backed up::

  ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""

And then ''cat /root/.ssh/id_rsa.pub'' for use later.

On the backup servers::

  sudo su -
  BUPUSER=bup-<short-servername>  # eg, bup-jenkins-dev
  useradd -r $BUPUSER -s /bin/bash -d /opt/backups/$BUPUSER -m
  cd /opt/backups/$BUPUSER
  mkdir .ssh
  cat >.ssh/authorized_keys

and add this to the authorized_keys file::

  command="BUP_DEBUG=0 BUP_FORCE_TTY=3 bup server",no-port-forwarding,no-agent-forwarding,no-X11-forwarding,no-pty <ssh key from earlier>

Switching back to the server to be backed up, run::

  ssh $BUPUSER@ci-backup-rs-ord.openstack.org
  ssh $BUPUSER@ci-backup-hp-az1.openstack.org

And verify the host key.  Note this will start the bup server on the
remote end, you will not be given a pty. Use ^D to close the connection
cleanly.  Add the "backup" class in puppet to the server
to be backed up.

Restore from Backup
-------------------

On the server that needs items restored from backup become root, start a
screen session as restoring can take a while, and create a working
directory to restore the backups into. This allows us to be selective in
how we restore content from backups::

  sudo su -
  screen
  mkdir /root/backup-restore-$DATE
  cd /root/backup-restore-$DATE

At this point we can join the tar that was split by the backup cron::

  bup join -r bup-<short-servername>@ci-backup-rs-ord.openstack.org: root > backup.tar

At this point you may need to wait a while. These backups are stored on
servers geographically distant from our normal servers resulting in less
network throughput between servers than we are used to.

Once the ``bup join`` is complete you will have a tar archive of that
backup. It may be useful to list the files in the backup
``tar -tf backup.tar`` to get an idea of what things are available. At
this point you will probably either want to extract the entire backup::

  tar -xvf backup.tar
  ls -al

Or selectively extract files::

  # path/to/file needs to match the output given by tar -t
  tar -xvf backup.tar path/to/file

Note if you created your working directory in a path that is not
excluded by bup you will want to remove that directory when your work is
done. /root/backup-restore-* is excluded so the path above is safe.

Launching New Servers
=====================

New servers are launched using the ``launch/launch-node.py`` tool from the git
repository ``https://git.openstack.org/openstack-infra/system-config``. This
tool is run from a checkout on the puppetmaster - please see :file:`launch/README`
for detailed instructions.

.. _disable-enable-puppet:

Disable/Enable Puppet
=====================

You should normally not make manual changes to servers, but instead,
make changes through puppet.  However, under some circumstances, you
may need to temporarily make a manual change to a puppet-managed
resource on a server.

OpenStack Infra uses a non-trivial combination of Dynamic and Static
Inventory in Ansible to control execution of puppet. A full understanding
of the concepts in
`Ansible Inventory Introduction
<http://docs.ansible.com/ansible/intro_inventory.html>`_
and
`Ansible Dynamic Inventory
<http://docs.ansible.com/ansible/intro_dynamic_inventory.html>`_
is essential for being able to make informed decisions about actions
to take.

In the case of needing to disable the running of puppet on a node, it's a
simple matter of adding an entry to the ansible inventory "disabled" group
in `:file:modules/openstack_project/files/puppetmaster/groups.txt`. The
disabled entry is an input to `ansible --list-hosts` so you can check your
entry simply by running it with `ansible $hostlist --list-hosts` as root
on the puppetmaster host and ensuring that the list of hosts returned is as
expected. Globs, group names and server UUIDs should all be acceptable input.

If you need to disable a host immediately without waiting for a patch to land
to `system-config`, there is a file on the puppetmaster host,
`/etc/ansible/hosts/emergency` that can be edited directly.

`/etc/ansible/hosts/emergency` is a file that should normally be empty, but
the contents are not managed by puppet. It's purpose is to allow for disabling
puppet at times when landing a change to the puppet repo would be either
unreasonable or impossible.

There are two sections in the emergency file, `disabled` and
`disabled:children`. To disable a single host, put it in `disabled`. If you
want to disable a group of hosts, put it in `disabled:children`. Any hosts we
have that have more than one host with the same name (such as in the case of
being in the midst of a migration) will show up as a group with the name of
the hostname and the individual servers will be listed by UUID.

Because of the way static and dynamic inventories get merged by ansible, the
emergency file needs to stand alone. If you need to disable a group of servers
from OpenStack you need to not only add it to `disabled:children`, you need to
add an emtpy group into the emergency file too.

Disabling puppet via ansible inventory does not disable puppet from being
able to be run directly on the host, it merely prevents ansible from
attempting to run it. If you choose to run puppet manually on a host, take care
to ensure that it has not been disabled at the puppetmaster level first.

Examples
--------

To disable an OpenStack instance called `amazing.openstack.org` temporarily
without landing a puppet change, ensure the following is in
`/etc/ansible/hosts/emergency`

::

  [disabled]
  amazing.openstack.org

To disable one of the OpenStack instances called `git.openstack.org`
temporarily without landing a puppet change but leaving the other running,
find its UUID via OpenStack tools and ensure it's in the emergency file.

::

  [disabled]
  811c5197-dba7-4d3a-a3f6-68ca5328b9a7

To disable a group of hosts in the emergency file, such as all of the pypi
hosts.

::

  [disabled:children]
  pypi

To disable a staticly defined host that is not an OpenStack host, such as
the Infra cloud controller hosts, put the following in groups.txt.

::

  disabled controller.useast.openstack.org

.. _cinder:

Cinder Volume Management
========================

Adding a New Device
-------------------

If the main volume group doesn't have enough space for what you want
to do, this is how you can add a new volume.

Log into puppetmaster.openstack.org and run::

  . ~root/cinder-venv/bin/activate
  . ~root/ci-launch/cinder.sh

  nova list
  cinder list

* Add a new 1024G cinder volume (substitute the hostname and the next number
  in series for NN)::

    cinder create --display-name "HOSTNAME.openstack.org/mainNN" 1024
    nova volume-attach <server id> <volume id> auto

* or to add a 100G SSD volume::

    cinder create --volume-type SSD --display-name "HOSTNAME.openstack.org/mainNN" 100
    nova volume-attach <server id> <volume id> auto

* Then, on the host, create the partition table::

    DEVICE=/dev/xvdX
    sudo parted $DEVICE mklabel msdos mkpart primary 0% 100% set 1 lvm on
    sudo pvcreate ${DEVICE}1

* It should show up in pvs::

    $ sudo pvs
      PV         VG   Fmt  Attr PSize    PFree
      /dev/xvdX1      lvm2 a-   1024.00g 1024.00g

* Add it to the main volume group::

    sudo vgextend main ${DEVICE}1

* However, if the volume group does not exist yet, you can create it::

    sudo vgcreate main ${DEVICE}1

Creating a New Logical Volume
-----------------------------

Make sure there is enough space in the volume group::

  $ sudo vgs
    VG   #PV #LV #SN Attr   VSize VFree
    main   4   2   0 wz--n- 2.00t 347.98g

If not, see `Adding a New Device`_.

Create the new logical volume and initialize the filesystem::

  NAME=newvolumename
  sudo lvcreate -L1500GB -n $NAME main

  sudo mkfs.ext4 -m 0 -j -L $NAME /dev/main/$NAME
  sudo tune2fs -i 0 -c 0 /dev/main/$NAME

Be sure to add it to ``/etc/fstab``.

Expanding an Existing Logical Volume
------------------------------------

Make sure there is enough space in the volume group::

  $ sudo vgs
    VG   #PV #LV #SN Attr   VSize VFree
    main   4   2   0 wz--n- 2.00t 347.98g

If not, see `Adding a New Device`_.

The following example increases the size of a volume by 100G::

  NAME=volumename
  sudo lvextend -L+100G /dev/main/$NAME
  sudo resize2fs /dev/main/$NAME
