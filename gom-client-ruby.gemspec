require 'rake'

# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require 'gom/client/version'

Gem::Specification.new do |s|
  s.name        = 'gom-client'
  s.version     = Gom::Client::VERSION
  s.date        = Gom::Client::DATE
  s.authors     = "ART+COM"
  s.homepage    = 'http://www.artcom.de/'
  s.summary     = 'REST client for the gom HTTP API'

  s.add_dependency 'json'

  s.add_development_dependency 'rspec'
  s.add_development_dependency 'guard'
  s.add_development_dependency 'guard-rspec'
  s.add_development_dependency 'rb-fsevent', '~>0.9.1'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'guard-rubocop'
  s.add_development_dependency 'chromatic'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'simplecov-rcov'

  if RUBY_PLATFORM.match /java/i
    s.add_development_dependency 'ruby-debug'
  else
    s.add_development_dependency 'debugger'
  end

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map do |f| 
    File.basename(f)
  end
  s.require_paths = ["lib"]
end
