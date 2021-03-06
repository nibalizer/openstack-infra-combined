# == Class: apps_site
#
class apps_site (
  $vhost_name              = $::fqdn,
  $root_dir                = '/opt/apps_site',
  $install_dir             = '/usr/local/lib/python2.7/dist-packages/openstack_catalog/',
  $serveradmin             = "webmaster@${::domain}",
  $commit                  = 'master',
  $ssl_cert_file_contents  = undef,
  $ssl_key_file_contents   = undef,
  $ssl_chain_file_contents = undef,
  $ssl_cert_file           = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  $ssl_key_file            = '/etc/ssl/private/ssl-cert-snakeoil.key',
  $ssl_chain_file          = '/etc/ssl/certs/ca-certificates.crt',
) {
  include ::httpd::ssl
  include ::httpd::mod::wsgi

  if !defined(Package['git']) {
    package { 'git':
      ensure => present
    }
  }

  vcsrepo { $root_dir:
    ensure   => latest,
    provider => git,
    revision => $commit,
    source   => 'https://git.openstack.org/openstack/app-catalog.git',
    require  => [
      Package['git'],
    ]
  }

  ::httpd::vhost { $vhost_name:
    port       => 443,
    docroot    => "${root_dir}/openstack_catalog/web",
    priority   => '50',
    template   => 'apps_site/vhost.erb',
    vhost_name => $vhost_name,
    ssl        => true,
  }

  httpd_mod { 'headers':
    ensure => present,
    notify => Service['httpd']
  }

  httpd_mod { 'rewrite':
    ensure => present,
    notify => Service['httpd']
  }

  httpd_mod { 'deflate':
    ensure => present,
    notify => Service['httpd']
  }

  if $ssl_cert_file_contents != undef {
    file { $ssl_cert_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_cert_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_key_file_contents != undef {
    file { $ssl_key_file:
      owner   => 'root',
      group   => 'ssl-cert',
      mode    => '0640',
      content => $ssl_key_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if $ssl_chain_file_contents != undef {
    file { $ssl_chain_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0640',
      content => $ssl_chain_file_contents,
      before  => Httpd::Vhost[$vhost_name],
    }
  }

  if ! defined(Package['python-yaml']) {
    package { 'python-yaml':
      ensure => present,
    }
  }

  if ($::lsbdistcodename == 'trusty') {
    if ! defined(Package['zopfli']) {
      package { 'zopfli':
        ensure => present,
      }
    }
  }

  exec { 'install-app_catalog' :
    command     => "/usr/local/bin/pip install --upgrade ${root_dir}",
    cwd         => $root_dir,
    refreshonly => true,
    subscribe   => Vcsrepo[$root_dir],
    notify      => Service['httpd'],
  }

  file { "${install_dir}/local_settings.py":
    ensure  => present,
    mode    => '0644',
    require => Exec['install-app_catalog'],
    content => template('apps_site/local_settings.erb'),
  }

  file { "${install_dir}/manage.py":
    ensure  => present,
    source  => "${root_dir}/manage.py",
    require => Exec['install-app_catalog'],
  }

  exec { 'collect-static' :
    command   => "/usr/bin/python ${install_dir}/manage.py collectstatic --noinput",
    subscribe => File["${install_dir}/manage.py"],
  }

  exec { 'python-compress' :
    command   => "/usr/bin/python ${install_dir}/manage.py compress --force",
    subscribe => File["${install_dir}/manage.py"],
  }

  exec { 'make_assets_json' :
    command     => "${root_dir}/tools/update_assets.sh",
    path        => '/usr/local/bin:/usr/bin:/bin',
    refreshonly => true,
    subscribe   => Vcsrepo[$root_dir],
  }

}
