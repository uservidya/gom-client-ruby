$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'gom/client'
require 'webmock/rspec'
require 'vcr'

module SpecHelpers

  def next_uniq_seq_no
    $__uniq_seq_no += 1
  end
  def uniq_node_uri(seq_no = next_uniq_seq_no)
    #t = Time.now
    #uri = "/some/random/node/n#{t.tv_sec}_#{t.tv_usec}"
    uri = "/test/node/n#{seq_no}"
  end
  def uniq_attr_uri(seq_no = next_uniq_seq_no)
    #t = Time.now
    #uri = "/some/random/node/n#{t.tv_usec}:a#{t.tv_usec}"
    uri = "/test/node/n#{seq_no}:a#{seq_no}"
  end
end


RSpec.configure do |config|

  $__uniq_seq_no = 1
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
