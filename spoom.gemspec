# typed: strict
# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "spoom/version"

Gem::Specification.new do |spec|
  spec.name          = "spoom"
  spec.version       = Spoom::VERSION
  spec.authors       = ["Alexandre Terrasa"]
  spec.email         = ["ruby@shopify.com"]

  spec.summary       = "Useful tools for Sorbet enthusiasts."
  spec.homepage      = "https://github.com/Shopify/spoom"
  spec.license       = "MIT"

  spec.bindir        = "exe"
  spec.executables   = ["spoom"]
  spec.require_paths = ["lib"]

  spec.files         = Dir.glob(["lib/**/*.rb", "templates/**/*.erb"]) + ["README.md", "Gemfile", "Rakefile"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.add_development_dependency("bundler", ">= 2.2.10")
  spec.add_development_dependency("minitest", "~> 5.0")
  spec.add_development_dependency("minitest-reporters")
  spec.add_development_dependency("rake", "~> 13.0.1")

  spec.add_dependency("sorbet", ">= 0.5.10187")
  spec.add_dependency("sorbet-runtime", ">= 0.5.9204")
  spec.add_dependency("thor", ">= 0.19.2")

  spec.required_ruby_version = ">= 2.7.0"
end
