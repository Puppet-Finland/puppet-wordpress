require 'spec_helper_acceptance'

describe 'wordpress' do

  it 'should work with no errors' do

    pp = <<-EOS
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
        listen          => ['127.0.0.1', 9000],
        # EL6 mod_proxy_fcgi doesn't support UDS
        #listen          => '/var/run/httpd/wordpress.sock',
        #listen_owner    => 'apache',
        #listen_group    => 'apache',
        #listen_mode     => '0666',
        pm              => 'static',
        pm_max_children => 5,
        user            => 'wordpress',
        require         => ::Wordpress::Instance['/srv/wordpress'],
      }

      include ::epel

      $mod_packages = $::operatingsystemmajrelease ? {
        '6'     => {
          'proxy_fcgi' => 'mod_proxy_fcgi',
        },
        default => {},
      }

      class { '::apache':
        default_mods  => false,
        default_vhost => false,
        mod_packages  => $mod_packages,
        trace_enable  => false,
        require       => Class['::epel'], # Necessary for EL6
      }

      include ::apache::mod::dir
      include ::apache::mod::proxy
      include ::apache::mod::proxy_fcgi

      ::apache::vhost { 'wordpress':
        docroot          => '/srv/wordpress',
        docroot_owner    => 'wordpress',
        docroot_group    => 'wordpress',
        directories      => [
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
          # { # EL6 doesn't support UDS
          #   'path'       => '\\.php$',
          #   'provider'   => 'filesmatch',
          #   'sethandler' => 'proxy:unix:/var/run/httpd/wordpress.sock|fcgi://localhost/',
          # },
        ],
        proxy_pass_match => [
          {
            'path' => '^/(.+\.php)$',
            'url'  => 'fcgi://127.0.0.1:9000/srv/wordpress/$1',
          },
        ],
        port             => 80,
        servername       => 'wordpress',
        require          => ::Php::Fpm::Pool['wordpress'],
      }

      package { 'fcgi':
        ensure  => present,
        require => Class['::epel'],
      }
    EOS

    # Second run will purge unmanaged settings
    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes:  true)
  end

  describe file('/srv/wordpress/index.php') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'wordpress' }
    it { is_expected.to be_grouped_into 'wordpress' }
    it { is_expected.to be_mode 644 }
  end

  describe file('/srv/wordpress/wp-config.php') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'wordpress' }
    it { is_expected.to be_grouped_into 'wordpress' }
    it { is_expected.to be_mode 644 }
  end

  describe command('SCRIPT_FILENAME=/srv/wordpress/wp-admin/install.php QUERY_STRING= REQUEST_METHOD=GET cgi-fcgi -bind -connect 127.0.0.1:9000') do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{(?mx) Welcome \s to \s the \s famous \s five-minute \s WordPress \s installation \s process!} }
  end

  describe command('curl -s http://localhost/wp-admin/install.php') do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{(?mx) Welcome \s to \s the \s famous \s five-minute \s WordPress \s installation \s process!} }
  end
end
