# Class: openstack_project::jenkins_params
#
# This class holds parameters that need to be
# accessed by other classes.
class openstack_project::jenkins_params {
  case $::osfamily {
    'RedHat': {
      #yum groupinstall "Development Tools"
      # packages needed by slaves
      $ant_package = 'ant'
      $awk_package = 'gawk'
      $asciidoc_package = 'asciidoc'
      $curl_package = 'curl'
      $docbook_xml_package = 'docbook-style-xsl'
      $docbook5_xml_package = 'docbook5-schemas'
      $docbook5_xsl_package = 'docbook5-style-xsl'
      $firefox_package = 'firefox'
      $graphviz_package = 'graphviz'
      $libcurl_dev_package = 'libcurl-devel'
      $ldap_dev_package = 'openldap-devel'
      # $libjerasure_dev_package = 'libjerasure-devel' not yet available
      $librrd_dev_package = 'rrdtool-devel'
      # packages needed by document translation
      $gnome_doc_package = 'gnome-doc-utils'
      $libtidy_package = 'libtidy'
      $gettext_package = 'gettext'
      $language_fonts_packages = []
      # for keystone ldap auth integration
      $libsasl_dev = 'cyrus-sasl-devel'
      $nspr_dev_package = 'nspr-devel'
      $sqlite_dev_package = 'sqlite-devel'
      $liberasurecode_dev_package = 'liberasurecode-devel'
      $libevent_dev_package = 'libevent-devel'
      $libpcap_dev_package = 'libpcap-devel'
      $libvirt_dev_package = 'libvirt-devel'
      $libxml2_package = 'libxml2'
      $libxml2_dev_package = 'libxml2-devel'
      $libxslt_dev_package = 'libxslt-devel'
      $libffi_dev_package = 'libffi-devel'
      # FIXME: No Maven packages on RHEL
      #$maven_package = 'maven'
      # For tooz unit tests
      $memcached_package = 'memcached'
      # For tooz unit tests (and others that use redis)
      $redis_package = 'redis'
      # For Ceilometer unit tests
      $mongodb_package = 'mongodb-server'
      $pandoc_package = 'pandoc'
      $pkgconfig_package = 'pkgconfig'
      # FIXME: no PyPy headers on RHEL
      # FIXME: no PyPy on RHEL
      # FIXME: no Python 3 headers on RHEL
      # FIXME: no Python 3 on RHEL
      $python_libvirt_package = 'libvirt-python'
      $python_lxml_package = 'python-lxml'
      $python_requests_package = 'python-requests'
      $python_zmq_package = 'python-zmq'
      $rubygems_package = 'rubygems'
      # Common Lisp interpreter, used for cl-openstack-client
      $sbcl_package = 'sbcl'
      $sqlite_package = 'sqlite'
      $unzip_package = 'unzip'
      $zip_package = 'zip'
      $xslt_package = 'libxslt'
      $xvfb_package = 'xorg-x11-server-Xvfb'
      # PHP package, used for community portal
      $php5_cli_package = 'php-cli'
      # FIXME: No zookeeper packages on RHEL
      #$zookeeper_package = 'zookeeper-server'
      $cgroups_package = 'libcgroup'
      if ($::operatingsystem == 'Fedora') and ($::operatingsystemrelease >= 19) {
        # From Fedora 19 and onwards there's no longer
        # support to mysql-devel.
        # Only community-mysql-devel. If you try to
        # install mysql-devel you get a conflict with
        # mariadb packages.
        $mysql_dev_package = 'community-mysql-devel'
        $mysql_package = 'community-mysql'
        $zookeeper_package = 'zookeeper'
        $cgroups_tools_package = 'libcgroup-tools'
        $cgconfig_require = [
          Package['cgroups'],
          Package['cgroups-tools'],
        ]
        $cgred_require = [
          Package['cgroups'],
          Package['cgroups-tools'],
        ]
        $dvipng_package = 'texlive-dvipng'
      } else {
        $mysql_dev_package = 'mysql-devel'
        $cgroups_tools_package = ''
        $cgconfig_require = Package['cgroups']
        $cgred_require = Package['cgroups']
        $dvipng_package = 'dvipng'
      }

      $uuid_dev = "libuuid-devel"
      $swig = "swig"
      $libjpeg_dev = "libjpeg-turbo-devel"
      $zlib_dev = "zlib-devel"
    }
    'Debian': {
      # packages needed by slaves
      $ant_package = 'ant'
      $awk_package = 'gawk'
      $asciidoc_package = 'asciidoc'
      $curl_package = 'curl'
      $docbook_xml_package = 'docbook-xml'
      $docbook5_xml_package = 'docbook5-xml'
      $docbook5_xsl_package = 'docbook-xsl'
      $dvipng_package = 'dvipng'
      $firefox_package = 'firefox'
      $graphviz_package = 'graphviz'
      $libcurl_dev_package = 'libcurl4-gnutls-dev'
      $libevent_dev_package = 'libevent-dev'
      $libpcap_dev_package = 'libpcap-dev'
      $ldap_dev_package = 'libldap2-dev'
      $liberasurecode_dev_package = 'liberasurecode-dev'
      $libjerasure_dev_package = 'libjerasure-dev'
      $librrd_dev_package = 'librrd-dev'
      # packages needed by document translation
      $gnome_doc_package = 'gnome-doc-utils'
      $libtidy_package = 'libtidy-0.99-0'
      $gettext_package = 'gettext'
      $language_fonts_packages = ['fonts-takao', 'fonts-nanum']
      # for keystone ldap auth integration
      $libsasl_dev = 'libsasl2-dev'
      $mysql_dev_package = 'libmysqlclient-dev'
      $nspr_dev_package = 'libnspr4-dev'
      $sqlite_dev_package = 'libsqlite3-dev'
      $libvirt_dev_package = 'libvirt-dev'
      $libxml2_package = 'libxml2-utils'
      $libxml2_dev_package = 'libxml2-dev'
      $libxslt_dev_package = 'libxslt1-dev'
      $libffi_dev_package = 'libffi-dev'
      $maven_package = 'maven2'
      # For tooz unit tests
      $memcached_package = 'memcached'
      # For tooz unit tests (and others that use redis)
      $redis_package = 'redis-server'
      # For Ceilometer unit tests
      $mongodb_package = 'mongodb'
      $pandoc_package = 'pandoc'
      $pkgconfig_package = 'pkg-config'
      $pypy_dev_package = 'pypy-dev'
      $pypy_package = 'pypy'
      $python3_dev_package = 'python3-all-dev'
      $python3_package = 'python3.4'
      $python_libvirt_package = 'python-libvirt'
      $python_lxml_package = 'python-lxml'
      $python_requests_package = 'python-requests'
      $python_zmq_package = 'python-zmq'
      if $::lsbdistcodename == 'precise' {
        $rubygems_package = 'rubygems'
      } else {
        $rubygems_package = 'ruby'
      }

      # Common Lisp interpreter, used for cl-openstack-client
      $sbcl_package = 'sbcl'
      $sqlite_package = 'sqlite3'
      $unzip_package = 'unzip'
      $zip_package = 'zip'
      $xslt_package = 'xsltproc'
      $xvfb_package = 'xvfb'
      # PHP package, used for community portal
      $php5_cli_package = 'php5-cli'
      $php5_mcrypt_package = 'php5-mcrypt'
      # For [tooz, taskflow, nova] using zookeeper in unit tests
      $zookeeper_package = 'zookeeperd'
      $cgroups_package = 'cgroup-bin'
      $cgroups_tools_package = ''
      $cgconfig_require = [
        Package['cgroups'],
        File['/etc/init/cgconfig.conf'],
      ]
      $cgred_require = [
        Package['cgroups'],
        File['/etc/init/cgred.conf'],
      ]

      $uuid_dev = "uuid-dev"
      $swig = "swig"
      $libjpeg_dev = "libjpeg-dev"
      $zlib_dev = "zlib1g-dev"
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} The 'jenkins' module only supports osfamily Debian or RedHat (slaves only).")
    }
  }
}
