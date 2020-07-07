# typed: true
# frozen_string_literal: true

require "thor"

module Spoom
  module Cli
    class Main < Thor
      extend T::Sig

      # Utils

      def self.exit_on_failure?
        true
      end
    end
  end
end
