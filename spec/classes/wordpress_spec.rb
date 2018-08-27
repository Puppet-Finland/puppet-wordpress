require 'spec_helper'

describe 'wordpress' do

  let(:pre_condition) do
    'include ::php'
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('wordpress') }
      it { is_expected.to contain_class('wordpress::config') }
      it { is_expected.to contain_class('wordpress::install') }
    end
  end
end
