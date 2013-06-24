require 'spec_helper'

describe Gom::Client do 
  it 'exists' do
    Gom::Client.should be_kind_of(Class)
  end

  context 'with gom.dev.artcom.de' do 
    let(:gom)     { Gom::Client.new('http://gom.dev.artcom.de') }
    let(:prefix)  { gom.create!("/tests", {}) }

    it 'retrieves node' do
      (hash = gom.retrieve prefix).should be_kind_of(Hash)
      (node = hash[:node]).should be_kind_of(Hash)
      node[:uri].should eq(prefix)
      node[:entries].should be
    end
  end
end
