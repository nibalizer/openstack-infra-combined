# Copyright 2014 Hewlett-Packard Development Company, L.P.
# Copyright 2015 Red Hat, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Class: stackalytics
#
class stackalytics (
  $stackalytics_ssh_private_key,
  $cron_hour = '*/1',
  $cron_minute = '0',
  $gerrit_ssh_user = 'stackalytics',
  $git_revision = 'master',
  $git_source = 'https://git.openstack.org/openstack/stackalytics',
  $memcached_listen_ip = '127.0.0.1',
  $memcached_max_memory = '4096',
  $memcached_port = '11211',
  $vhost_name = $::fqdn,
) {
  include ::httpd
  include ::httpd::mod::wsgi
  include ::pip
  include ::logrotate

  $packages = [
    'libapache2-mod-proxy-uwsgi',
    'libapache2-mod-uwsgi',
    'uwsgi',
    'uwsgi-plugin-python',
  ]
  package { $packages:
    ensure => present,
  }

  class { '::memcached':
    # NOTE(pabelanger): current requirement is about 2.5Gb and it increases on
    # approx 0.5Gb per year
    listen_ip  => $memcached_listen_ip,
    max_memory => $memcached_max_memory,
    tcp_port   => $memcached_port,
    udp_port   => $memcached_port,
  }

  group { 'stackalytics':
    ensure => present,
  }

  user { 'stackalytics':
    ensure     => present,
    home       => '/home/stackalytics',
    shell      => '/bin/bash',
    gid        => 'stackalytics',
    managehome => true,
    require    => Group['stackalytics'],
  }

  file { '/home/stackalytics/.ssh':
    ensure  => directory,
    mode    => '0500',
    owner   => 'stackalytics',
    group   => 'stackalytics',
    require => User['stackalytics'],
  }

  file { '/home/stackalytics/.ssh/id_rsa':
    ensure  => present,
    content => $stackalytics_ssh_private_key,
    mode    => '0400',
    owner   => 'stackalytics',
    group   => 'stackalytics',
    require => File['/home/stackalytics/.ssh'],
  }

  file { '/opt/git':
    ensure  => directory,
    owner   => 'stackalytics',
    group   => 'stackalytics',
    mode    => '0644',
    require => User['stackalytics'],
  }

  vcsrepo { '/opt/stackalytics':
    ensure   => latest,
    provider => git,
    revision => $git_revision,
    source   => $git_source,
  }

  exec { 'install-stackalytics':
    command     => 'pip install /opt/stackalytics',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/stackalytics'],
    notify      => Exec['stackalytics-reload'],
    require     => Class['pip'],
  }

  file { '/var/run/stackalytics':
    ensure => directory,
    group  => 'stackalytics',
    mode   => '0644',
    owner  => 'stackalytics',
  }

  cron { 'process_stackalytics':
    user        => 'stackalytics',
    hour        => $cron_hour,
    command     => 'flock -n /var/run/stackalytics/stackalytics.lock /usr/local/bin/stackalytics-processor',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    minute      => $cron_minute,
    require     => [
      Exec['install-stackalytics'],
      File['/var/run/stackalytics'],
    ],
  }

  cron { 'stackalytics_dump_restore':
    user        => 'stackalytics',
    command     => 'flock -n /var/run/stackalytics/stackalytics.lock /usr/local/bin/stackalytics-dump --restore --file /var/log/stackalytics/dump.log',
    environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
    require     => [
        Exec['install-stackalytics'],
        File['/var/log/stackalytics/dump.log'],
    ],
    special     => 'reboot',
  }

  file { '/etc/stackalytics':
    ensure => directory,
  }

  file { '/var/log/stackalytics':
    ensure => directory,
  }

  file { '/var/log/stackalytics/dump.log':
    ensure  => file,
    require => File['/var/log/stackalytics'],
  }

  ::logrotate::file { 'stackalytics':
    log        => '/var/log/stackalytics/dump.log',
    options    => [
      'compress',
      'daily',
      'missingok',
      'create 640 stackalytics adm',
      'rotate 7',
    ],
    postrotate => '/usr/local/bin/stackalytics-dump --file /var/log/stackalytics/dump.log',
    require    => File['/var/log/stackalytics/dump.log'],
  }

  file { '/etc/stackalytics/stackalytics.conf':
    ensure  => link,
    owner   => 'stackalytics',
    mode    => '0444',
    target  => '/opt/stackalytics/etc/stackalytics.conf',
    notify  => Exec['stackalytics-reload'],
    require => [
      File['/etc/stackalytics'],
      User['stackalytics'],
      Vcsrepo['/opt/stackalytics'],
    ],
  }

  # TODO(pabelanger): Use upstream uwsgi puppet module over embedding this.
  # Also expose settings to allow user to better configure.
  file { '/etc/uwsgi/apps-enabled/stackalytics.ini':
    ensure  => present,
    owner   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/stackalytics/uwsgi.ini',
    notify  => [
      Exec['stackalytics-reload'],
      Service['uwsgi'],
    ],
    require => Package['uwsgi'],
  }

  service { 'uwsgi':
    ensure     => running,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['uwsgi'],
  }

  exec { 'stackalytics-reload':
    command     => 'touch /usr/local/lib/python2.7/dist-packages/stackalytics/dashboard/web.wsgi',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
  }

  ::httpd::vhost { $vhost_name:
    port     => 80,
    docroot  => 'MEANINGLESS ARGUMENT',
    priority => '50',
    template => 'stackalytics/stackalytics.vhost.erb',
    ssl      => true,
  }

  httpd::mod { 'proxy':
    ensure => present,
  }

  httpd::mod { 'proxy_http':
    ensure => present,
  }

  httpd::mod { 'proxy_uwsgi':
    ensure  => present,
    require => Package[$packages],
  }

  ini_setting { 'sources_root':
    ensure  => present,
    notify  => Exec['stackalytics-reload'],
    path    => '/etc/stackalytics/stackalytics.conf',
    require => File['/etc/stackalytics/stackalytics.conf'],
    section => 'DEFAULT',
    setting => 'sources_root',
    value   => '/opt/git',
  }

  ini_setting { 'ssh_key_filename':
    ensure  => present,
    notify  => Exec['stackalytics-reload'],
    path    => '/etc/stackalytics/stackalytics.conf',
    require => File['/etc/stackalytics/stackalytics.conf'],
    section => 'DEFAULT',
    setting => 'ssh_key_filename',
    value   => '/home/stackalytics/.ssh/id_rsa',
  }

  ini_setting { 'ssh_username':
    ensure  => present,
    notify  => Exec['stackalytics-reload'],
    path    => '/etc/stackalytics/stackalytics.conf',
    require => File['/etc/stackalytics/stackalytics.conf'],
    section => 'DEFAULT',
    setting => 'ssh_username',
    value   => $gerrit_ssh_user,
  }
}
