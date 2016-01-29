# Copyright 2013  OpenStack Foundation
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
# openstackid idp(sso-openid) server
#
class openstack_project::openstackid_prod (
  $sysadmins = [],
  $site_admin_password = '',
  $id_mysql_host = '',
  $id_mysql_user = '',
  $id_mysql_password = '',
  $id_db_name = '',
  $ss_mysql_host = '',
  $ss_mysql_user = '',
  $ss_mysql_password = '',
  $ss_db_name = '',
  $redis_port = '6378',
  $redis_max_memory = '1gb',
  $redis_bind = '127.0.0.1',
  $redis_password = '',
  $redis_version = '2.2.12',
  $id_recaptcha_public_key = '',
  $id_recaptcha_private_key = '',
  $id_recaptcha_template = '',
  $id_log_error_to_email = '',
  $id_log_error_from_email = '',
  $id_environment = 'dev',
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $release = '1.0.7',
  $app_url = '',
  $app_key = '',
) {

  class { 'openstack_project::server':
    iptables_public_tcp_ports => [80, 443],
    sysadmins                 => $sysadmins,
  }

  class { 'openstackid':
    site_admin_password      => $site_admin_password,
    id_mysql_host            => $id_mysql_host,
    id_mysql_user            => $id_mysql_user,
    id_mysql_password        => $id_mysql_password,
    id_db_name               => $id_db_name,
    ss_mysql_host            => $ss_mysql_host,
    ss_mysql_user            => $ss_mysql_user,
    ss_mysql_password        => $ss_mysql_password,
    ss_db_name               => $ss_db_name,
    redis_port               => $redis_port,
    redis_host               => $redis_bind,
    redis_password           => $redis_password,
    id_recaptcha_public_key  => $id_recaptcha_public_key,
    id_recaptcha_private_key => $id_recaptcha_private_key,
    id_recaptcha_template    => $id_recaptcha_template,
    id_log_error_to_email    => $id_log_error_to_email,
    id_log_error_from_email  => $id_log_error_from_email,
    id_environment           => $id_environment,
    ssl_cert_file            => "/etc/ssl/certs/${::fqdn}.pem",
    ssl_key_file             => "/etc/ssl/private/${::fqdn}.key",
    ssl_chain_file           => '/etc/ssl/certs/intermediate.pem',
    ssl_cert_file_contents   => $ssl_cert_file_contents,
    ssl_key_file_contents    => $ssl_key_file_contents,
    ssl_chain_file_contents  => $ssl_chain_file_contents,
    openstackid_release      => $release,
    app_url                  => $app_url,
    app_key                  => $app_key,
  }

  # redis (custom module written by tipit)
  class { 'redis':
    redis_port       => $redis_port,
    redis_max_memory => $redis_max_memory,
    redis_bind       => $redis_bind,
    redis_password   => $redis_password,
    version          => $redis_version ,
  }

  mysql_backup::backup_remote { $id_db_name:
    database_host     => $id_mysql_host,
    database_user     => $id_mysql_user,
    database_password => $id_mysql_password,
  }

  mysql_backup::backup_remote { $ss_db_name:
    database_host     => $ss_mysql_host,
    database_user     => $ss_mysql_user,
    database_password => $ss_mysql_password,
    num_backups       => 2, # big and presumably also backed up by www.o.o
  }
}
