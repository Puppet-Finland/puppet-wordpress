require 'spec_helper'

describe 'Wordpress::Version' do
  it { is_expected.to allow_values('latest', '1.0', '4.9.1') }
  it { is_expected.not_to allow_values('invalid', '1', '1.0.0.0', 1) }
end
