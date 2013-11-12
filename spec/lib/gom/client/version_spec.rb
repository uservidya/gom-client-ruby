require 'spec_helper'

describe Gom::Client::VERSION do
  it 'defines a VERSION' do
    Gom::Client::VERSION.should be_kind_of(String)
    Gom::Client::VERSION.should match(/\d\.\d\.\d/)
  end
end
