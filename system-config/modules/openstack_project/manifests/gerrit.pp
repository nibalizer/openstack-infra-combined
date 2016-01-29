# == Class: openstack_project::gerrit
#
# A wrapper class around the main gerrit class that sets gerrit
# up for launchpad single sign on and bug/blueprint links

class openstack_project::gerrit (
  $mysql_host,
  $mysql_password,
  $vhost_name = $::fqdn,
  $canonicalweburl = "https://${::fqdn}/",
  $serveradmin = 'webmaster@openstack.org',
  $ssh_host_key = '/home/gerrit2/review_site/etc/ssh_host_rsa_key',
  $ssh_project_key = '/home/gerrit2/review_site/etc/ssh_project_rsa_key',
  $ssl_cert_file = "/etc/ssl/certs/${::fqdn}.pem",
  $ssl_key_file = "/etc/ssl/private/${::fqdn}.key",
  $ssl_chain_file = '/etc/ssl/certs/intermediate.pem',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $ssh_dsa_key_contents = '', # If left empty puppet will not create file.
  $ssh_dsa_pubkey_contents = '', # If left empty puppet will not create file.
  $ssh_rsa_key_contents = '', # If left empty puppet will not create file.
  $ssh_rsa_pubkey_contents = '', # If left empty puppet will not create file.
  $ssh_project_rsa_key_contents = '', # If left empty will not create file.
  $ssh_project_rsa_pubkey_contents = '', # If left empty will not create file.
  $ssh_welcome_rsa_key_contents='', # If left empty will not create file.
  $ssh_welcome_rsa_pubkey_contents='', # If left empty will not create file.
  $ssh_replication_rsa_key_contents='', # If left empty will not create file.
  $ssh_replication_rsa_pubkey_contents='', # If left empty will not create file.
  $email = '',
  $database_poollimit = '',
  $container_heaplimit = '',
  $core_packedgitopenfiles = '',
  $core_packedgitlimit = '',
  $core_packedgitwindowsize = '',
  $sshd_threads = '',
  $httpd_acceptorthreads = '',
  $httpd_minthreads = '',
  $httpd_maxthreads = '',
  $httpd_maxwait = '',
  $war = '',
  $contactstore = false,
  $contactstore_appsec = '',
  $contactstore_pubkey = '',
  $contactstore_url = '',
  $acls_dir = 'UNDEF',
  $notify_impact_file = 'UNDEF',
  $projects_file = 'UNDEF',
  $projects_config = 'UNDEF',
  $github_username = '',
  $github_oauth_token = '',
  $github_project_username = '',
  $github_project_password = '',
  $trivial_rebase_role_id = '',
  $email_private_key = '',
  $token_private_key = '',
  $replicate_local = true,
  $replication_force_update = true,
  $replication = [],
  $local_git_dir = '/opt/lib/git',
  $jeepyb_cache_dir = '/opt/lib/jeepyb',
  $cla_description = 'OpenStack Individual Contributor License Agreement',
  $cla_file = 'static/cla.html',
  $cla_id = '2',
  $cla_name = 'ICLA',
  $testmode = false,
  $swift_username = '',
  $swift_password = '',
  $gitweb = true,
  $cgit = false,
  $web_repo_url = '',
  $web_repo_url_encode = false,
  $secondary_index = true,
  $report_bug_text = 'Get Help',
  $report_bug_url = 'http://docs.openstack.org/infra/system-config/project.html#contributing',
  $index_threads = 1,
) {

  class { 'jeepyb::openstackwatch':
    projects       => [
      'openstack/ceilometer',
      'openstack/cinder',
      'openstack/glance',
      'openstack/heat',
      'openstack/horizon',
      'openstack/infra',
      'openstack/keystone',
      'openstack/nova',
      'openstack/oslo',
      'openstack/neutron',
      'openstack/swift',
      'openstack/tempest',
      'openstack-dev/devstack',
    ],
    container      => 'rss',
    json_url       => 'https://review.openstack.org/query?q=status:open',
    swift_username => $swift_username,
    swift_password => $swift_password,
    swift_auth_url => 'https://auth.api.rackspacecloud.com/v1.0',
    auth_version   => '1.0',
  }

  class { '::gerrit':
    vhost_name                          => $vhost_name,
    canonicalweburl                     => $canonicalweburl,
    # opinions
    allow_drafts                        => false,
    enable_melody                       => true,
    melody_session                      => true,
    robots_txt_source                   => 'puppet:///modules/openstack_project/gerrit/robots.txt',
    enable_javamelody_top_menu          => false,
    # passthrough
    ssl_cert_file                       => $ssl_cert_file,
    ssl_key_file                        => $ssl_key_file,
    ssl_chain_file                      => $ssl_chain_file,
    ssl_cert_file_contents              => $ssl_cert_file_contents,
    ssl_key_file_contents               => $ssl_key_file_contents,
    ssl_chain_file_contents             => $ssl_chain_file_contents,
    ssh_dsa_key_contents                => $ssh_dsa_key_contents,
    ssh_dsa_pubkey_contents             => $ssh_dsa_pubkey_contents,
    ssh_rsa_key_contents                => $ssh_rsa_key_contents,
    ssh_rsa_pubkey_contents             => $ssh_rsa_pubkey_contents,
    ssh_project_rsa_key_contents        => $ssh_project_rsa_key_contents,
    ssh_project_rsa_pubkey_contents     => $ssh_project_rsa_pubkey_contents,
    ssh_replication_rsa_key_contents    => $ssh_replication_rsa_key_contents,
    ssh_replication_rsa_pubkey_contents => $ssh_replication_rsa_pubkey_contents,
    email                               => $email,
    openidssourl                        => 'https://login.launchpad.net/+openid',
    database_poollimit                  => $database_poollimit,
    container_heaplimit                 => $container_heaplimit,
    core_packedgitopenfiles             => $core_packedgitopenfiles,
    core_packedgitlimit                 => $core_packedgitlimit,
    core_packedgitwindowsize            => $core_packedgitwindowsize,
    sshd_threads                        => $sshd_threads,
    httpd_acceptorthreads               => $httpd_acceptorthreads,
    httpd_minthreads                    => $httpd_minthreads,
    httpd_maxthreads                    => $httpd_maxthreads,
    httpd_maxwait                       => $httpd_maxwait,
    commentlinks                        => [
      {
        name  => 'bugheader',
        match => '([Cc]loses|[Pp]artial|[Rr]elated)-[Bb]ug:\\s*#?(\\d+)',
        link  => 'https://launchpad.net/bugs/$2',
      },
      {
        name  => 'bug',
        match => '\\b[Bb]ug:? #?(\\d+)',
        link  => 'https://launchpad.net/bugs/$1',
      },
      {
        name  => 'story',
        match => '\\b[Ss]tory:? #?(\\d+)',
        link  => 'https://storyboard.openstack.org/#!/story/$1',
      },
      {
        name  => 'blueprint',
        match => '(\\b[Bb]lue[Pp]rint\\b|\\b[Bb][Pp]\\b)[ \\t#:]*([A-Za-z0-9\\-]+)',
        link  => 'https://blueprints.launchpad.net/openstack/?searchtext=$2',
      },
      {
        name  => 'testresult',
        match => '<li>([^ ]+) <a href=\"[^\"]+\" target=\"_blank\">([^<]+)</a> : ([^ ]+)([^<]*)</li>',
        html  => '<li class=\"comment_test\"><span class=\"comment_test_name\"><a href=\"$2\">$1</a></span> <span class=\"comment_test_result\"><span class=\"result_$3\">$3</span>$4</span></li>',
      },
      {
        name  => 'launchpadbug',
        match => '<a href=\"(https://bugs\\.launchpad\\.net/[a-zA-Z0-9\\-]+/\\+bug/(\\d+))[^\"]*\">[^<]+</a>',
        html  => '<a href=\"$1\">$1</a>'
      },
      {
        name  => 'changeid',
        match => '(I[0-9a-f]{8,40})',
        link  => '/#q,$1,n,z',
      },
      {
        name  => 'gitsha',
        match => '(<p>|[\\s(])([0-9a-f]{40})(</p>|[\\s.,;:)])',
        html  => '$1<a href=\"/#q,$2,n,z\">$2</a>$3',
      },
    ],
    trackingids                         => [
      {
        name   => 'storyboard',
        footer => 'story:',
        match  => '\\#?(\\d+)',
        system => 'Storyboard',
      },
    ],
    war                                 => $war,
    contactstore                        => $contactstore,
    contactstore_appsec                 => $contactstore_appsec,
    contactstore_pubkey                 => $contactstore_pubkey,
    contactstore_url                    => $contactstore_url,
    mysql_host                          => $mysql_host,
    mysql_password                      => $mysql_password,
    email_private_key                   => $email_private_key,
    token_private_key                   => $token_private_key,
    replicate_local                     => $replicate_local,
    replicate_path                      => $local_git_dir,
    replication_force_update            => $replication_force_update,
    replication                         => $replication,
    gitweb                              => $gitweb,
    cgit                                => $cgit,
    web_repo_url                        => $web_repo_url,
    web_repo_url_encode                 => $web_repo_url_encode,
    testmode                            => $testmode,
    secondary_index                     => $secondary_index,
    require                             => Class[openstack_project::server],
    report_bug_text                     => $report_bug_text,
    report_bug_url                      => $report_bug_url,
    index_threads                       => $index_threads,
  }

  mysql_backup::backup_remote { 'gerrit':
    database_host     => $mysql_host,
    database_user     => 'gerrit2',
    database_password => $mysql_password,
    require           => Class['::gerrit'],
  }

  if ($testmode == false) {
    include gerrit::cron
    class { 'github':
      username         => $github_username,
      project_username => $github_project_username,
      project_password => $github_project_password,
      oauth_token      => $github_oauth_token,
      require          => Class['::gerrit']
    }
  }

  file { '/home/gerrit2/review_site/static/cla.html':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/gerrit/cla.html',
    replace => true,
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/static/usg-cla.html':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/gerrit/usg-cla.html',
    replace => true,
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/static/system-cla.html':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0444',
    source  => 'puppet:///modules/openstack_project/gerrit/system-cla.html',
    replace => true,
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/static/title.png':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/openstack.png',
    require => Class['::gerrit'],
    notify => Exec['reload_gerrit_header'],
  }

  file { '/home/gerrit2/review_site/static/openstack-page-bkg.jpg':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/openstack-page-bkg.jpg',
    require => Class['::gerrit'],
  }

  package { 'libjs-jquery':
    ensure => present,
  }

  file { '/home/gerrit2/review_site/static/jquery.js':
    ensure  => present,
    source  => '/usr/share/javascript/jquery/jquery.js',
    require     => [
        File['/home/gerrit2/review_site/static'],
        Class['::gerrit'],
        Package['libjs-jquery'],
      ],
    subscribe   => Package['libjs-jquery'],
    notify      => Exec['reload_gerrit_header'],
  }

  vcsrepo { '/opt/jquery-visibility':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/mathiasbynens/jquery-visibility.git',
  }

  file { '/home/gerrit2/review_site/static/jquery-visibility.js':
    ensure => present,
    source => '/opt/jquery-visibility/jquery-visibility.js',
    subscribe => Vcsrepo['/opt/jquery-visibility'],
    notify => Exec['reload_gerrit_header'],
    require => [ File['/home/gerrit2/review_site/static'],
                 Class['::gerrit'] ]
  }

  file { '/home/gerrit2/review_site/static/hideci.js':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/gerrit/hideci.js',
    require => Class['::gerrit'],
    notify => Exec['reload_gerrit_header'],
  }

  file { '/home/gerrit2/review_site/etc/GerritSite.css':
    ensure  => present,
    source  => 'puppet:///modules/openstack_project/gerrit/GerritSite.css',
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/etc/GerritSiteHeader.html':
    ensure  => present,
    source  =>
      'puppet:///modules/openstack_project/gerrit/GerritSiteHeader.html',
    require => Class['::gerrit'],
  }

  exec { 'reload_gerrit_header':
    command     => 'sleep 10; touch /home/gerrit2/review_site/etc/GerritSiteHeader.html',
    path        => '/bin:/usr/bin',
    refreshonly => true,
  }

  cron { 'gerritsyncusers':
    ensure => absent,
  }

  cron { 'sync_launchpad_users':
    ensure => absent,
  }

  file { '/home/gerrit2/review_site/hooks/change-merged':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/gerrit/change-merged',
    replace => true,
    require => Class['::gerrit'],
  }

  file { '/home/gerrit2/review_site/hooks/change-abandoned':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/openstack_project/gerrit/change-abandoned',
    replace => true,
    require => Class['::gerrit'],
  }

  if ($notify_impact_file != 'UNDEF') {
    file { '/home/gerrit2/review_site/hooks/notify_impact.yaml':
      ensure  => present,
      source  => $notify_impact_file,
      require => Class['::gerrit'],
    }
  }

  file { '/home/gerrit2/review_site/hooks/patchset-created':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    content => template('openstack_project/gerrit_patchset-created.erb'),
    replace => true,
    require => Class['::gerrit'],
  }

  if $ssh_welcome_rsa_key_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_welcome_rsa_key':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0600',
      content => $ssh_welcome_rsa_key_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  if $ssh_welcome_rsa_pubkey_contents != '' {
    file { '/home/gerrit2/review_site/etc/ssh_welcome_rsa_key.pub':
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0644',
      content => $ssh_welcome_rsa_pubkey_contents,
      replace => true,
      require => File['/home/gerrit2/review_site/etc']
    }
  }

  if ($projects_file != 'UNDEF') {
    if ($replicate_local) {
      if (!defined(File[$local_git_dir])) {
        file { $local_git_dir:
          ensure  => directory,
          owner   => 'gerrit2',
          require => Class['::gerrit'],
        }
        cron { 'mirror_repack':
          user        => 'gerrit2',
          weekday     => '0',
          hour        => '4',
          minute      => '7',
          command     => "find ${local_git_dir} -type d -name \"*.git\" -print -exec git --git-dir=\"{}\" repack -afd \\;",
          environment => 'PATH=/usr/bin:/bin:/usr/sbin:/sbin',
        }
      }
    }

    file { '/home/gerrit2/projects.yaml':
      ensure  => present,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0444',
      source  => $projects_file,
      replace => true,
      require => Class['::gerrit'],
    }

    file { $jeepyb_cache_dir:
      ensure => 'directory',
      owner  => 'gerrit2',
      group  => 'gerrit2',
      mode   => '0755',
    }

    file { '/home/gerrit2/projects.ini':
      ensure  => present,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0444',
      content => template($projects_config),
      replace => true,
      require => Class['::gerrit'],
    }

    file { '/home/gerrit2/acls':
      ensure  => directory,
      owner   => 'gerrit2',
      group   => 'gerrit2',
      mode    => '0444',
      recurse => true,
      replace => true,
      purge   => true,
      force   => true,
      source  => $acls_dir,
      require => Class['::gerrit']
    }

    if ($testmode == false) {
      exec { 'manage_projects':
        command     => '/usr/local/bin/manage-projects -v -l /var/log/manage_projects.log',
        timeout     => 1800, # 30 minutes
        subscribe   => [
            File['/home/gerrit2/projects.yaml'],
            File['/home/gerrit2/acls'],
          ],
        refreshonly => true,
        logoutput   => true,
        require     => [
            File['/home/gerrit2/projects.yaml'],
            File['/home/gerrit2/acls'],
            Class['jeepyb'],
          ],
      }

      include logrotate
      logrotate::file { 'manage_projects.log':
        log     => '/var/log/manage_projects.log',
        options => [
          'compress',
          'missingok',
          'rotate 30',
          'daily',
          'notifempty',
          'copytruncate',
        ],
        require => Exec['manage_projects'],
      }
    }
  }
  file { '/home/gerrit2/review_site/bin/set_agreements.sh':
    ensure  => absent,
  }
}
