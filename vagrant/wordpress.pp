class { '::mysql::server':
  root_password => 'vagrant',
}

include ::php
include ::wordpress

::wordpress::instance { '/srv/wordpress':
  owner       => 'apache',
  db_name     => 'wordpress',
  db_user     => 'wordpress',
  db_password => 'vagrant',
}

class { '::apache':
  default_mods  => false,
  default_vhost => false,
}

include ::apache::mod::dir
include ::apache::mod::php

::apache::vhost { 'wordpress':
  docroot     => '/srv/wordpress',
  directories => [
    {
      'path'           => '/srv/wordpress',
      'allow_override' => [
        'FileInfo',
      ],
      'directoryindex' => 'index.php',
      'options'        => [
        'FollowSymlinks',
      ],
    },
    {
      'path'       => '\\.php$',
      'provider'   => 'filesmatch',
      'sethandler' => 'application/x-httpd-php',
    },
  ],
  port        => 80,
  servername  => 'wordpress.local',
  require     => ::Wordpress::Instance['/srv/wordpress'],
}
