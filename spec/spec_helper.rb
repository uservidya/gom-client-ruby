$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'gom/client'

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


  config.before :each do
  end

  config.after :each do
  end
end
