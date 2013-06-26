$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'gom/client'
require 'webmock/rspec'
require 'vcr'

module SpecHelpers
  def uniq_node_uri
    t = Time.now
    uri = "/some/random/node/n#{t.tv_sec}_#{t.tv_usec}"
  end
  def uniq_attr_uri
    t = Time.now
    uri = "/some/random/node/n#{t.tv_usec}:a#{t.tv_usec}"
  end
end


RSpec.configure do |config|

  config.include SpecHelpers

  VCR.configure do |c|
    basedir = File.dirname(__FILE__)
    c.cassette_library_dir = File.join(basedir, 'fixtures', 'vcr_cassettes')
    c.allow_http_connections_when_no_cassette = true
    c.hook_into :webmock # or :fakeweb
  end

  config.before :each do
  end

  config.after :each do
  end
end
