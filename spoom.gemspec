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
  spec.add_development_dependency("rake", "~> 13.1.0")

  spec.add_dependency("erubi", ">= 1.10.0")
  spec.add_dependency("sorbet-static-and-runtime", ">= 0.5.10187")
  spec.add_dependency("syntax_tree", ">= 6.1.1")
  spec.add_dependency("thor", ">= 0.19.2")

  spec.required_ruby_version = ">= 3.0.0"
end
