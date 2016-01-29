# Class: ulimit::params
#
# This class holds parameters that need to be
# accessed by other classes.
class ulimit::params {
  case $::osfamily {
    'RedHat': {
      $pam_packages = ['pam']
    }
    'Debian': {
      $pam_packages = ['libpam-modules', 'libpam-modules-bin']
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'ulimit' module only supports osfamily Debian or RedHat.")
    }
  }
}
