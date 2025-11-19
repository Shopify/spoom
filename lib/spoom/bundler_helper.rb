# typed: strict
# frozen_string_literal: true

module Spoom
  module BundlerHelper
    extend T::Sig

    class << self
      # Generate a gem requirement for the given gem name, using that gem's version in the "real" current bundle.
      #
      # This ensures that any child Spoom::Contexts use predictable gem versions,
      # without having to manually specify them and bump them to stay in sync with Spoom's real Gemfile.
      #
      # Given `"foo"`, returns a string like 'gem "foo", "= 1.2.3"', suitable for inserting into a Gemfile.
      #: (String) -> String
      def gem_requirement_from_real_bundle(gem_name)
        specs = Bundler.load.gems[gem_name]

        if 1 < specs.count
          raise <<~MSG
            Found multiple versions of #{gem_name.inspect} in the current bundle:
            #{specs.sort_by(&:version).map { |spec| "  - #{spec.name} #{spec.version}" }.join("\n")}
          MSG
        end

        unless (spec = specs.first)
          raise "Did not find gem #{gem_name.inspect} in the current bundle"
        end

        %(gem "#{spec.name}", "= #{spec.version}")
      end
    end
  end
end
