$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'chromatic'

require 'webmock/rspec'
require 'vcr'

# COVERAGE env variable controls if coverage data is collected and the output
# format at the same time.
# COVERAGE values:
#  * html -> uses default html formatter
#  * rcov -> uses rcov-formatter (mainly useful for jenkins)
if ENV['COVERAGE']
  puts ' * Performing coverage via simplecov'.yellow
  require 'simplecov'
  require 'simplecov-rcov'
  SIMPLECOV_FORMATTERS = {
    html: SimpleCov::Formatter::HTMLFormatter,
    rcov: SimpleCov::Formatter::RcovFormatter
  }
  
  SimpleCov.formatter = SIMPLECOV_FORMATTERS.fetch(
                          ENV['COVERAGE'].to_sym,
                          SIMPLECOV_FORMATTERS[:html])
  puts "    * using formatter #{SimpleCov.formatter}".yellow
  SimpleCov.start do
    add_filter '/spec/'
    # TODO use add_group as soon as we have a meaningful grouping
  end
else
  puts ' * NOT Performing coverage via simplecov'.yellow
end

require 'gom/client'

module SpecHelpers
  
  class << self
    attr_accessor :seq_no
    @seq_no = 1
  end
  
  def next_uniq_seq_no
    SpecHelpers.seq_no += 1
  end
  
  def uniq_node_uri(seq_no = next_uniq_seq_no)
    "/test/node/n#{seq_no}"
  end
  
  def uniq_attr_uri(seq_no = next_uniq_seq_no)
    "/test/node/n#{seq_no}:a#{seq_no}"
  end
end

RSpec.configure do |config|

  SpecHelpers.seq_no = 1
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
