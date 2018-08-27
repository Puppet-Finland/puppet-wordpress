require 'spec_helper'

describe 'wordpress::instance' do

  let(:title) do
    '/srv/test'
  end

  let(:params) do
    {
      owner:       'test',
      db_name:     'test',
      db_user:     'test',
      db_password: 'test',
    }
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      context 'without wordpress class included' do
        it { is_expected.to compile.and_raise_error(%r{must include the wordpress base class}) }
      end

      context 'with wordpress class included' do
        let(:pre_condition) do
          'include ::php include ::wordpress'
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_archive('/tmp/latest.tar.gz') }
        it { is_expected.to contain_exec('restorecon -R /srv/test') }
        it { is_expected.to contain_file('/srv/test') }
        it { is_expected.to contain_file('/srv/test/wp-config.php') }
        it { is_expected.to contain_mysql__db('test') }
        it { is_expected.to contain_selinux__fcontext('/srv/test(/.*)?') }
      end
    end
  end
end
