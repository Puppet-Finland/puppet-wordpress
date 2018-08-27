require 'spec_helper_acceptance'

describe 'wordpress' do

  it 'should work with no errors' do

    pp = <<-EOS
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
        trace_enable  => false,
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
        servername  => 'wordpress',
        require     => ::Wordpress::Instance['/srv/wordpress'],
      }
    EOS

    # Second run will purge unmanaged settings
    apply_manifest(pp, catch_failures: true)
    apply_manifest(pp, catch_changes:  true)
  end

  describe file('/srv/wordpress/index.php') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'apache' }
    it { is_expected.to be_grouped_into 'apache' }
    it { is_expected.to be_mode 644 }
  end

  describe file('/srv/wordpress/wp-config.php') do
    it { is_expected.to be_file }
    it { is_expected.to be_owned_by 'apache' }
    it { is_expected.to be_grouped_into 'apache' }
    it { is_expected.to be_mode 644 }
  end

  describe command('curl -s http://localhost/wp-admin/install.php') do
    its(:exit_status) { is_expected.to eq 0 }
    its(:stdout) { is_expected.to match %r{(?mx) Welcome \s to \s the \s famous \s five-minute \s WordPress \s installation \s process!} }
  end
end
