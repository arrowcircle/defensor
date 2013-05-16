# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'defensor'

Gem::Specification.new do |spec|
  spec.name          = "defensor"
  spec.version       = Defensor::Version::VERSION
  spec.authors       = ["Oleg Bovykin"]
  spec.email         = ["oleg.bovykin@gmail.com"]
  spec.description   = %q{Unofficial Ruby library for Defensio 2.0}
  spec.summary       = %q{Unofficial Ruby library for Defensio 2.0}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard-rspec"

  spec.add_dependency "json"
  spec.add_dependency "facets"
  spec.add_dependency "httparty"
end
