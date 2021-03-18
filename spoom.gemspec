# typed: true
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
  spec.executables   = %w{spoom}
  spec.require_paths = ["lib"]

  spec.files         = Dir.glob(["lib/**/*.rb", "templates/**/*.erb"]) + %w(
    README.md
    Gemfile
    Rakefile
  )

  spec.metadata['allowed_push_host'] = "https://rubygems.org"

  spec.add_development_dependency("bundler", "~> 1.17")
  spec.add_development_dependency("rake", "~> 13.0.1")
  spec.add_development_dependency("minitest", "~> 5.0")

  spec.add_dependency("sorbet-runtime")
  spec.add_dependency("sorbet", "~> 0.5.5")
  spec.add_dependency("thor", ">= 0.19.2")
  spec.add_dependency("colorize")

  spec.required_ruby_version = ">= 2.3.7"
end
