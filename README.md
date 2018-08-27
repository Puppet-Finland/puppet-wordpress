# wordpress

Tested with Travis CI

[![Build Status](https://travis-ci.com/bodgit/puppet-wordpress.svg?branch=master)](https://travis-ci.com/bodgit/puppet-wordpress)
[![Coverage Status](https://coveralls.io/repos/bodgit/puppet-wordpress/badge.svg?branch=master&service=github)](https://coveralls.io/github/bodgit/puppet-wordpress?branch=master)
[![Puppet Forge](http://img.shields.io/puppetforge/v/bodgit/wordpress.svg)](https://forge.puppetlabs.com/bodgit/wordpress)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with wordpress](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with wordpress](#beginning-with-wordpress)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Description

This module manages Wordpress installations.

CentOS, RHEL, Scientific and Oracle Enterprise Linux is supported using Puppet
4.9.0 or later. SELinux is managed so it can remain enabled.

## Setup

### Setup Requirements

You will need to have already instantiated the
[puppetlabs/mysql](https://forge.puppet.com/puppetlabs/mysql) and
[bodgit/php](https://forge.puppet.com/bodgit/php) modules prior to using this
module.

### Beginning with wordpress

In the very simplest case, you can just include the base class which doesn't
do anything apart from install the necessary PHP extensions.

```puppet
class { '::mysql::server':
  root_password => 'password',
}

include ::php
include ::wordpress
```

## Usage

To create a Wordpress instance:

```puppet
class { '::mysql::server':
  root_password => 'password',
}

include ::php
include ::wordpress

::wordpress::instance { '/srv/wordpress':
  owner       => 'apache',
  db_name     => 'wordpress',
  db_user     => 'wordpress',
  db_password => 'secret',
}
```

Getting the file ownership right is the hardest part depending on what
webserver will be doing the serving. The above will work fine for Apache using
`mod_php` which you can extend with the necessary vhost:

```puppet
class { '::mysql::server':
  root_password => 'password',
}

include ::php
include ::wordpress

::wordpress::instance { '/srv/wordpress':
  owner       => 'apache',
  db_name     => 'wordpress',
  db_user     => 'wordpress',
  db_password => 'secret',
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
  servername  => 'example.com',
  require     => ::Wordpress::Instance['/srv/wordpress'],
}
```

If you prefer to use the PHP FastCGI Process Manager (which is recommended),
then the above can be rewritten as follows:

```puppet
class { '::mysql::server':
  root_password => 'password',
}

include ::php
include ::php::fpm
include ::wordpress

group { 'wordpress':
  ensure     => present,
  forcelocal => true,
}

user { 'wordpress':
  ensure   => present,
  comment  => 'Wordpress',
  gid      => 'wordpress',
  home     => '/srv/wordpress',
  password => '*',
  shell    => '/sbin/nologin',
}

::wordpress::instance { '/srv/wordpress':
  owner       => 'wordpress',
  db_name     => 'wordpress',
  db_user     => 'wordpress',
  db_password => 'secret',
}

::php::fpm::pool { 'wordpress':
  listen          => '/var/run/httpd/wordpress.sock',
  listen_owner    => 'apache',
  listen_group    => 'apache',
  listen_mode     => '0666',
  pm              => 'static',
  pm_max_children => 5,
  user            => 'wordpress',
  require         => ::Wordpress::Instance['/srv/wordpress'],
}

class { '::apache':
  default_mods  => false,
  default_vhost => false,
}

include ::apache::mod::dir
include ::apache::mod::proxy
include ::apache::mod::proxy_fcgi

::apache::vhost { 'wordpress':
  docroot       => '/srv/wordpress',
  docroot_owner => 'wordpress',
  docroot_group => 'wordpress',
  directories   => [
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
      'sethandler' => 'proxy:unix:/var/run/httpd/wordpress.sock|fcgi://localhost/',
    },
  ],
  port          => 80,
  servername    => 'wordpress',
  require       => ::Php::Fpm::Pool['wordpress'],
}
```

## Reference

The reference documentation is generated with
[puppet-strings](https://github.com/puppetlabs/puppet-strings) and the latest
version of the documentation is hosted at
[https://bodgit.github.io/puppet-wordpress/](https://bodgit.github.io/puppet-wordpress/).

## Limitations

This module has been built on and tested against Puppet 4.9.0 and higher.

The module has been tested on:

* CentOS Enterprise Linux 6/7

Currently the module assumes the MySQL database is local to the installation.

## Development

The module has both [rspec-puppet](http://rspec-puppet.com) and
[beaker-rspec](https://github.com/puppetlabs/beaker-rspec) tests. Run them
with:

```
$ bundle exec rake test
$ PUPPET_INSTALL_TYPE=agent PUPPET_INSTALL_VERSION=x.y.z bundle exec rake beaker:<nodeset>
```

Please log issues or pull requests at
[github](https://github.com/bodgit/puppet-wordpress).
