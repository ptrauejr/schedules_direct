# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'schedules_direct/version'

Gem::Specification.new do |spec|
  spec.name          = "schedules_direct"
  spec.version       = SchedulesDirect::VERSION
  spec.authors       = ["David M. Lary"]
  spec.email         = ["dmlary@gmail.com"]
  spec.summary       = %q{Work with the Schedules Direct JSON API}
  spec.homepage      = "https://github.com/dmlary/schedules_direct"
  spec.license       = "BSD 3-Clause"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency 'rest_client'
end
