# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cheflow/version'

Gem::Specification.new do |spec|
  spec.name          = "cheflow"
  spec.version       = Cheflow::VERSION
  spec.authors       = ["Joel Moss"]
  spec.email         = ["joel@developwithstyle.com"]
  spec.summary       = %q{A Cookbook-Centric workflow tool}
  spec.description   = %q{A CLI for managing Chef Environments using Berkshelf and the [slightly modified] Environment Cookbook Pattern.}
  spec.homepage      = "https://github.com/joelmoss/cheflow"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "semverse",          "~> 1.2"
  spec.add_dependency "berkshelf",         "~> 3.3"
  spec.add_dependency "ridley",            "~> 4.2"
  spec.add_dependency "ridley-connectors", "~> 2.3"
  spec.add_dependency "thor",              "~> 0.19"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake"
end
