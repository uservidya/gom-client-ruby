$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'gom/client'

RSpec.configure do |config|
  config.before :each do
  end

  config.after :each do
  end
end
