# == Class: openstack_project::single_use_slave
#
# This class configures single use Jenkins slaves with a few
# toggleable options. Most importantly sudo rights for the Jenkins
# user are by default off but can be enabled. Also, automatic_upgrades
# are off by default as the assumption is the backing image for
# this single use slaves will be refreshed with new packages
# periodically.
class openstack_project::single_use_slave (
  $certname = $::fqdn,
  $install_users = true,
  $install_resolv_conf = true,
  $sudo = false,
  $thin = true,
  $automatic_upgrades = false,
  $all_mysql_privs = false,
  $enable_unbound = true,
  $ssh_key = $openstack_project::jenkins_ssh_key,
  $jenkins_gitfullname = 'OpenStack Jenkins',
  $jenkins_gitemail = 'jenkins@openstack.org',
  $project_config_repo = 'https://git.openstack.org/openstack-infra/project-config',
) inherits openstack_project {
  class { 'openstack_project::template':
    certname            => $certname,
    automatic_upgrades  => $automatic_upgrades,
    install_users       => $install_users,
    install_resolv_conf => $install_resolv_conf,
    enable_unbound      => $enable_unbound,
    iptables_rules4     =>
      [
        # Ports 69 and 6385 allow to allow ironic VM nodes to reach tftp and
        # the ironic API from the neutron public net
        '-p udp --dport 69 -s 172.24.4.0/23 -j ACCEPT',
        '-p tcp --dport 6385 -s 172.24.4.0/23 -j ACCEPT',
        # Ports 8000, 8003, 8004 from the devstack neutron public net to allow
        # nova servers to reach heat-api-cfn, heat-api-cloudwatch, heat-api
        '-p tcp --dport 8000 -s 172.24.4.0/23 -j ACCEPT',
        '-p tcp --dport 8003 -s 172.24.4.0/23 -j ACCEPT',
        '-p tcp --dport 8004 -s 172.24.4.0/23 -j ACCEPT',
        '-m limit --limit 2/min -j LOG --log-prefix "iptables dropped: "',
      ],
  }
  class { 'jenkins::slave':
    ssh_key         => $ssh_key,
    gitfullname     => $jenkins_gitfullname,
    gitemail        => $jenkins_gitemail,
  }

  class { 'openstack_project::slave_common':
    sudo                => $sudo,
    project_config_repo => $project_config_repo,
  }

  if (! $thin) {
    class { 'openstack_project::thick_slave':
      all_mysql_privs => $all_mysql_privs,
    }
  }

}
