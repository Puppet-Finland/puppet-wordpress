# Install a Wordpress instance.
#
# @example Sample installation
#   include ::wordpress
#
#   ::wordpress::instance { '/var/www/html':
#     owner       => 'apache',
#     db_name     => 'wordpress',
#     db_user     => 'wordpress',
#     db_password => 'secret',
#   }
#
# @param owner
# @param db_name
# @param db_user
# @param db_password
# @param db_host
# @param docroot
# @param auth_key
# @param secure_auth_key
# @param logged_in_key
# @param nonce_key
# @param auth_salt
# @param secure_auth_salt
# @param logged_in_salt
# @param nonce_salt
# @param group
# @param version
#
# @see puppet_classes::wordpress ::wordpress
#
# @since 1.0.0
define wordpress::instance (
  String               $owner,
  String               $db_name,
  String               $db_user,
  String               $db_password,
  String               $db_host          = 'localhost',
  Stdlib::Absolutepath $docroot          = $title,
  String               $auth_key         = fqdn_rand_string(64, undef, 0),
  String               $secure_auth_key  = fqdn_rand_string(64, undef, 1),
  String               $logged_in_key    = fqdn_rand_string(64, undef, 2),
  String               $nonce_key        = fqdn_rand_string(64, undef, 3),
  String               $auth_salt        = fqdn_rand_string(64, undef, 4),
  String               $secure_auth_salt = fqdn_rand_string(64, undef, 5),
  String               $logged_in_salt   = fqdn_rand_string(64, undef, 6),
  String               $nonce_salt       = fqdn_rand_string(64, undef, 7),
  String               $group            = $owner,
  Wordpress::Version   $version          = 'latest',
) {

  if ! defined(Class['::wordpress']) {
    fail('You must include the wordpress base class before using any wordpress defined resources')
  }

  $filename = $version ? {
    'latest' => 'latest.tar.gz',
    default  => "wordpress-${version}.tar.gz",
  }

  if $::selinux {
    # Otherwise Wordpress can't update itself or plugins, etc.
    ::selinux::fcontext { "${docroot}(/.*)?":
      seltype => 'httpd_sys_rw_content_t',
      before  => File[$docroot],
    }

    exec { "restorecon -R ${docroot}":
      path        => $::path,
      refreshonly => true,
      subscribe   => [
        ::Selinux::Fcontext["${docroot}(/.*)?"],
        File[$docroot],
        Archive["/tmp/${filename}"],
        File["${docroot}/wp-config.php"],
      ],
    }
  }

  file { $docroot:
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    recurse => true,
  }

  archive { "/tmp/${filename}":
    path            => "/tmp/${filename}",
    source          => "https://wordpress.org/${filename}",
    checksum_type   => 'sha1',
    checksum_url    => "https://wordpress.org/${filename}.sha1",
    user            => $owner,
    group           => $group,
    extract         => true,
    extract_command => 'tar xfz %s --strip-components=1',
    extract_path    => $docroot,
    creates         => "${docroot}/index.php",
    require         => File[$docroot],
  }

  file { "${docroot}/wp-config.php":
    ensure  => file,
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    content => template("${module_name}/wp-config.php.erb"),
    require => Archive["/tmp/${filename}"],
  }

  ::mysql::db { $db_name:
    user     => $db_user,
    password => $db_password,
    host     => $db_host,
    grant    => ['ALL'],
  }
}
