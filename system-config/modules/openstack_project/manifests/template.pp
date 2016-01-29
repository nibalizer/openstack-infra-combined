# == Class: openstack_project::template
#
# A template host with no running services
#
class openstack_project::template (
  $iptables_public_tcp_ports = [],
  $iptables_public_udp_ports = [],
  $iptables_rules4           = [],
  $iptables_rules6           = [],
  $pin_puppet                = '3.',
  $install_users             = true,
  $install_resolv_conf       = true,
  $automatic_upgrades        = true,
  $certname                  = $::fqdn,
  $ca_server                 = undef,
  $enable_unbound            = true,
  $afs                       = false,
  $afs_cache_size            = 500000,
  $puppetmaster_server       = 'puppetmaster.openstack.org',
  $manage_exim               = false,
  $sysadmins                 = [],
  $pypi_index_url            = 'https://pypi.python.org/simple',
  $pypi_trusted_hosts        = [
    'pypi.bhs1.openstack.org',
    'pypi.dfw.openstack.org',
    'pypi.gra1.openstack.org',
    'pypi.iad.openstack.org',
    'pypi.nyj01.openstack.org',
    'pypi.ord.openstack.org',
    'pypi.region-b.geo-1.openstack.org',
    'pypi.regionone.openstack.org',
    'mirror.bhs1.ovh.openstack.org',
    'mirror.dfw.rax.openstack.org',
    'mirror.gra1.ovh.openstack.org',
    'mirror.iad.rax.openstack.org',
    'mirror.nyj01.internap.openstack.org',
    'mirror.ord.rax.openstack.org',
    'mirror.region-b.geo-1.hpcloud.openstack.org',
    'mirror.regionone.bluebox-sjc1.openstack.org',
  ],
  $purge_apt_sources         = false,
) {

  ###########################################################
  # Classes for all hosts

  include ntp
  include snmpd
  include sudoers

  include openstack_project::params
  include openstack_project::users

  class { 'ssh':
    trusted_ssh_source => $puppetmaster_server,
  }

  if ( $afs ) {
    $all_udp = concat(
      $iptables_public_udp_ports, [7001])

    class { 'openafs::client':
      cell         => 'openstack.org',
      realm        => 'OPENSTACK.ORG',
      admin_server => 'kdc.openstack.org',
      cache_size   => $afs_cache_size,
      kdcs         => [
        'kdc01.openstack.org',
        'kdc02.openstack.org',
      ],
    }
  } else {
    $all_udp = $iptables_public_udp_ports
  }

  class { 'iptables':
    public_tcp_ports => $iptables_public_tcp_ports,
    public_udp_ports => $all_udp,
    rules4           => $iptables_rules4,
    rules6           => $iptables_rules6,
  }

  class { 'timezone':
    timezone => 'Etc/UTC',
  }


  ###########################################################
  # Process if ( $high_level_directive ) blocks

  if $manage_exim {
    class { 'exim':
      sysadmins => $sysadmins,
    }
  }

  if $automatic_upgrades == true {
    class { 'openstack_project::automatic_upgrades':
      origins => ["Puppetlabs:${lsbdistcodename}"],
    }
  }

  class {'openstack_project::users_install':
    install_users => $install_users
  }

  if ($enable_unbound) {
    class { 'unbound':
      install_resolv_conf => $install_resolv_conf
    }
  }

  if ($::in_chroot) {
    notify { 'rsyslog in chroot':
      message => 'rsyslog not refreshed, running in chroot',
    }
    $rsyslog_notify = []
  } else {
    service { 'rsyslog':
      ensure     => running,
      enable     => true,
      hasrestart => true,
      require    => Package['rsyslog'],
    }
    $rsyslog_notify = [ Service['rsyslog'] ]
  }

  ###########################################################
  # System tweaks

  # Increase syslog message size in order to capture
  # python tracebacks with syslog.
  file { '/etc/rsyslog.d/99-maxsize.conf':
    ensure  => present,
    # Note MaxMessageSize is not a puppet variable.
    content => '$MaxMessageSize 6k',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => $rsyslog_notify,
    require => Package['rsyslog'],
  }

  # We don't like byobu
  file { '/etc/profile.d/Z98-byobu.sh':
    ensure => absent,
  }

  if $::osfamily == 'Debian' {

    # Custom rsyslog config to disable /dev/xconsole noise on Debuntu servers
    file { '/etc/rsyslog.d/50-default.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      source  =>
        'puppet:///modules/openstack_project/rsyslog.d_50-default.conf',
      replace => true,
      notify  => $rsyslog_notify,
      require => Package['rsyslog'],
    }

    # Ubuntu installs their whoopsie package by default, but it eats through
    # memory and we don't need it on servers
    package { 'whoopsie':
      ensure => absent,
    }

    package { 'popularity-contest':
      ensure => absent,
    }
  }

  ###########################################################
  # Package resources for all operating systems

  package { 'lvm2':
    ensure => present,
  }

  package { 'strace':
    ensure => present,
  }

  package { 'tcpdump':
    ensure => present,
  }

  package { 'rsyslog':
    ensure => present,
  }

  package { 'git':
    ensure => present,
  }

  package { 'rsync':
    ensure => present,
  }

  package { $::openstack_project::params::packages:
    ensure => present
  }

  ###########################################################
  # Package resources for specific operating systems

  case $::osfamily {
    'Debian': {
      # Purge and augment existing /etc/apt/sources.list if requested
      class { '::apt':
        purge => { 'sources.list' => $purge_apt_sources }
      }
      if $purge_apt_sources == true {
        file { '/etc/apt/sources.list.d/openstack-infra.list':
          ensure => present,
          group  => 'root',
          mode   => '0444',
          owner  => 'root',
          source => "puppet:///modules/openstack_project/sources.list.${::lsbdistcodename}",
        }
      }

      # Make sure dig is installed
      package { 'dnsutils':
        ensure => present,
      }
    }
    'RedHat': {
      # Make sure dig is installed
      package { 'bind-utils':
        ensure => present,
      }
    }
  }

  ###########################################################
  # Manage  python/pip

  $desired_virtualenv = '13.1.0'
  class { '::pip':
    index_url       => $pypi_index_url,
    trusted_hosts   => $pypi_trusted_hosts,
    optional_settings => {
      'extra-index-url' => '',
    },
    manage_pip_conf => true,
  }

  if (( versioncmp($::virtualenv_version, $desired_virtualenv) < 0 )) {
    $virtualenv_ensure = $desired_virtualenv
  } else {
    $virtualenv_ensure = present
  }
  package { 'virtualenv':
    ensure   => $virtualenv_ensure,
    provider => pip,
    require  => Class['pip'],
  }

  ###########################################################
  # Manage Root ssh

  if ! defined(File['/root/.ssh']) {
    file { '/root/.ssh':
      ensure => directory,
      mode   => '0700',
    }
  }

  ssh_authorized_key { 'puppet-remote-2014-04-17':
    ensure  => absent,
    user    => 'root',
  }
  ssh_authorized_key { 'puppet-remote-2014-05-24':
    ensure  => absent,
    user    => 'root',
  }
  ssh_authorized_key { 'puppet-remote-2014-09-11':
    ensure  => absent,
    user    => 'root',
  }

  ssh_authorized_key { 'puppet-remote-2014-09-15':
    ensure  => present,
    user    => 'root',
    type    => 'ssh-rsa',
    key     => 'AAAAB3NzaC1yc2EAAAADAQABAAABAQDSLlN41ftgxkNeUi/kATYPwMPjJdMaSbgokSb9PSkRPZE7GeNai60BCfhu+ky8h5eMe70Bpwb7mQ7GAtHGXPNU1SRBPhMuVN9EYrQbt5KSiwuiTXtQHsWyYrSKtB+XGbl2PhpMQ/TPVtFoL5usxu/MYaakVkCEbt5IbPYNg88/NKPixicJuhi0qsd+l1X1zoc1+Fn87PlwMoIgfLIktwaL8hw9mzqr+pPcDIjCFQQWnjqJVEObOcMstBT20XwKj/ymiH+6p123nnlIHilACJzXhmIZIZO+EGkNF7KyXpcBSfv9efPI+VCE2TOv/scJFdEHtDFkl2kdUBYPC0wQ92rp',
    options => [
      'from="puppetmaster.openstack.org"',
    ],
    require => File['/root/.ssh'],
  }
  ssh_authorized_key { '/root/.ssh/authorized_keys':
    ensure  => absent,
    user    => 'root',
  }

  file_line { 'ensure NoRoaming for ssh clients':
    after => '^Host *',
    path  => '/etc/ssh/ssh_config',
    line  => '    UseRoaming no',
  }

  ###########################################################
  # Manage Puppet
  # possible TODO: break this into openstack_project::puppet

  case $pin_puppet {
    '2.7.': {
      $pin_facter = '1.'
      $pin_puppetdb = '1.'
    }
    /^3\./: {
      $pin_facter = '2.'
      $pin_puppetdb = '2.'
    }
    default: {
      fail("Puppet version not supported")
    }
  }

  if ($::operatingsystem == 'Fedora') {

    package { 'hiera':
      ensure   => latest,
      provider => 'gem',
    }

    exec { 'symlink hiera modules' :
      command     => 'ln -s /usr/local/share/gems/gems/hiera-puppet-* /etc/puppet/modules/',
      path        => '/bin:/usr/bin',
      subscribe   => Package['hiera'],
      refreshonly => true,
    }

  }

  # Which Puppet do I take?
  # Take $puppet_version and pin to that version
  if ($::osfamily == 'Debian') {
    # Note(JR): Puppetlabs does not support Ubuntu Vivid currently, but it
    # also seems that distro packages are recent enough
    if ($::operatingsystemrelease != '15.04') {
      apt::source { 'puppetlabs':
        location => 'http://apt.puppetlabs.com',
        repos    => 'main',
        key      => {
          'id'     =>'47B320EB4C7C375AA9DAE1A01054B7A24BD6EC30',
          'server' => 'pgp.mit.edu',
        },
      }
    }

    file { '/etc/apt/apt.conf.d/80retry':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/80retry',
      replace => true,
    }

    file { '/etc/apt/apt.conf.d/90no-translations':
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/90no-translations',
      replace => true,
    }

    file { '/etc/apt/preferences.d/00-puppet.pref':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      content => template('openstack_project/00-puppet.pref.erb'),
      replace => true,
    }

    file { '/etc/default/puppet':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/puppet.default',
      replace => true,
    }

  }

  if ($::operatingsystem == 'CentOS') {
    if ($::operatingsystemmajrelease == '6') {
      $puppet_repo_source_path =
        'puppet:///modules/openstack_project/centos6-puppetlabs.repo'
      $custom_cgit = present
    } elsif ($::operatingsystemmajrelease == '7') {
      $puppet_repo_source_path =
        'puppet:///modules/openstack_project/centos7-puppetlabs.repo'
      $custom_cgit = absent
    }
    file { '/etc/yum.repos.d/puppetlabs.repo':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => $puppet_repo_source_path,
      replace => true,
    }

    # This git package includes a small work-around for slow https
    # cloning performance, as discussed in redhat bz#1237395.  Should
    # be fixed in 6.8
    file { '/etc/yum.repos.d/git-1237395.repo':
      ensure  => $custom_cgit,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/git-1237395.repo',
      replace => true,
    }

    file { '/etc/yum.conf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0444',
      source  => 'puppet:///modules/openstack_project/yum.conf',
      replace => true,
    }
  }

  $puppet_version = $pin_puppet
  file { '/etc/puppet/puppet.conf':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    content => template('openstack_project/puppet.conf.erb'),
    replace => true,
  }

  service { 'puppet':
    ensure => stopped,
  }

  file { '/etc/puppet/hiera.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/puppet/hiera.yaml',
    replace => true,
  }

  file {'/etc/puppet/environments':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file {'/etc/puppet/environments/production':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file {'/etc/puppet/environments/production/environment.conf':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/openstack_project/puppet/production_environment.conf',
  }
  ###########################################################

}
