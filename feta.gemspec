# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "feta/version"

Gem::Specification.new do |s|
  s.name        = "feta"
  s.version     = Feta::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Duncan Mac-Vicar P."]
  s.email       = ["dmacvicar@suse.de"]
  s.homepage    = "http://github.com/dmacvicar/feta"
  s.summary     = %q{Library to access FATE features}
  s.description = %q{Feta is a library to access FATE using the keeper API}

  s.add_dependency("rest-client", ["~> 1.6"])
  s.add_dependency("nokogiri", ["~> 1.5"])
  s.add_dependency("inifile", ["~> 0.4.1"])

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
