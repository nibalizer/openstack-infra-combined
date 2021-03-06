# Class: iptables
#
# http://projects.puppetlabs.com/projects/1/wiki/Module_Iptables_Patterns
#
# params:
#   rules4: A list of additional iptables v4 rules
#          eg: [ '-m udp -p udp -s 127.0.0.1 --dport 8125 -j ACCEPT' ]
#   rules6: A list of additional iptables v6 rules
#          eg: [ '-m udp -p udp -s ::1 --dport 8125 -j ACCEPT' ]
#   public_tcp_ports: List of integer TCP ports on which to allow all traffic
#   public_udp_ports: List of integer UDP ports on which to allow all traffic
class iptables(
  $rules4 = [],
  $rules6 = [],
  $public_tcp_ports = [],
  $public_udp_ports = []
) {

  include ::iptables::params

  package { 'iptables':
    ensure => present,
    name   => $::iptables::params::package_name,
  }

  if ($::in_chroot) {
    notify { 'iptables in chroot':
      message => 'Iptables not refreshed, running in chroot',
    }
    $notify_iptables = []
  }
  else {
    service { 'iptables':
      name       => $::iptables::params::service_name,
      require    => Package['iptables'],
      hasstatus  => $::iptables::params::service_has_status,
      status     => $::iptables::params::service_status_cmd,
      hasrestart => $::iptables::params::service_has_restart,
      enable     => true,
    }
    $notify_iptables = Service['iptables']

    # On centos 7 firewalld and iptables-service confuse each other and you
    # end up with no firewall rules at all. Disable firewalld so that
    # iptables-service can be in charge.
    if ($::osfamily == 'RedHat' and $::operatingsystemmajrelease >= '7') {
      exec { 'stop-firewalld-if-running':
        command => '/usr/bin/systemctl stop firewalld',
        onlyif  => '/usr/bin/pgrep firewalld',
      }
      package { 'firewalld':
        ensure  => 'purged',
        require => Exec['stop-firewalld-if-running'],
        before  => Package['iptables'],
      }
    }
  }

  file { $::iptables::params::rules_dir:
    ensure  => directory,
    require => Package['iptables'],
  }

  # This file is not required on Red Hat distros... but it
  # won't hurt to softlink to it either
  file { "${::iptables::params::rules_dir}/rules":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('iptables/rules.erb'),
    require => [
      Package['iptables'],
      File[$::iptables::params::rules_dir],
    ],
    # When this file is updated, make sure the rules get reloaded.
    notify  => $notify_iptables,
  }

  file { $::iptables::params::ipv4_rules:
    ensure  => link,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    target  => "${::iptables::params::rules_dir}/rules",
    require => File["${::iptables::params::rules_dir}/rules"],
    notify  => $notify_iptables,
  }

  file { $::iptables::params::ipv6_rules:
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => template('iptables/rules.v6.erb'),
    require => [
      Package['iptables'],
      File[$::iptables::params::rules_dir],
    ],
    # When this file is updated, make sure the rules get reloaded.
    notify  => $notify_iptables,
    replace => true,
  }
}
