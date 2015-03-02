# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-appdynamics"
  gem.version       = "0.0.1"
  gem.date          = '2015-03-02'
  gem.authors       = ["chandrashekar Tippur"]
  gem.email         = ["ctippur@gmail.com"]
  gem.summary       = %q{Fluentd input plugin for appdynamics alerts}
  gem.description   = %q{FLuentd plugin for appdynamics alerts... WIP}
  gem.homepage      = 'https://github.com/Bigel0w/fluent-plugin-appdynamics'
  gem.license       = 'MIT'

  gem.files         = README.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]
  # Add GEM dependencies below
  # For Example: gem.add_development_dependency "rake", '~> 0.9', '>= 0.9.6'
  gem.add_runtime_dependency "fluentd", '~> 0.10', '>= 0.10.52'
  gem.add_runtime_dependency "json", '~> 1.1', '>= 1.8.2'
  gem.add_runtime_dependency "rest_client", '~> 1.1', '>= 1.8.3'
end
