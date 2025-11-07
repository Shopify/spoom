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

  spec.files         = Dir.glob([
    "lib/**/*.rb",
    "templates/**/*.erb",
  ]) + ["README.md", "Gemfile", "Rakefile", "rbi/spoom.rbi"]

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.add_development_dependency("bundler", ">= 2.2.10")
  spec.add_development_dependency("minitest-reporters")
  spec.add_development_dependency("rake", "~> 13.3.0")

  spec.add_dependency("erubi", ">= 1.10.0")
  spec.add_dependency("prism", ">= 0.28.0")
  spec.add_dependency("rbi", ">= 0.3.3")
  # Any version constraint changes to `rbs` should be reflected in the Gemfile used by the `export` command
  # https://github.com/Shopify/spoom/blob/c094851a8aff3760d06b85655eba624dc2ad769b/lib/spoom/cli/srb/sigs.rb#L148
  spec.add_dependency("rbs", ">= 4.0.0.dev.4")
  spec.add_dependency("rexml", ">= 3.2.6")
  spec.add_dependency("sorbet-static-and-runtime", ">= 0.5.10187")
  spec.add_dependency("thor", ">= 0.19.2")

  spec.required_ruby_version = ">= 3.2"
end
