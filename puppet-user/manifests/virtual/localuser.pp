# usage
#
# user::virtual::localuser['username']

define user::virtual::localuser(
  $realname,
  $uid,
  $gid,
  $sshkeys,
  $groups     = [ 'sudo', 'admin', ],
  $key_id     = $title,
  $old_keys   = [],
  $shell      = '/bin/bash',
  $home       = "/home/${title}",
  $managehome = true
) {

  group { $title:
    ensure => present,
    gid    => $gid,
  }

  user { $title:
    ensure     => present,
    comment    => $realname,
    uid        => $uid,
    gid        => $gid,
    groups     => $groups,
    home       => $home,
    managehome => $managehome,
    membership => 'minimum',
    shell      => $shell,
    require    => Group[$title],
  }

  # ensure that home exists with the right permissions
  file { $home:
    ensure  => directory,
    owner   => $title,
    group   => $title,
    mode    => '0755',
    require => [ User[$title], Group[$title] ],
  }

  # Ensure the .ssh directory exists with the right permissions
  file { "${home}/.ssh":
    ensure  => directory,
    owner   => $title,
    group   => $title,
    mode    => '0700',
    require => File[$home],
  }

  ssh_authorized_key { $key_id:
    ensure  => present,
    key     => $sshkeys,
    user    => $title,
    type    => 'ssh-rsa',
    require => File[ "${home}/.ssh" ],
  }

  if ( $old_keys != [] ) {
    ssh_authorized_key { $old_keys:
      ensure => absent,
      user   => $title,
    }
  }
}

# vim:sw=2:ts=2:expandtab:textwidth=79
