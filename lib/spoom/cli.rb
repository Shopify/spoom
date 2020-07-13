# typed: true
# frozen_string_literal: true

require "thor"

require_relative "cli/commands/config"
module Spoom
  module Cli
    class Main < Thor
      extend T::Sig

      desc "config", "manage Sorbet config"
      subcommand "config", Spoom::Cli::Commands::Config

      # Utils

      def self.exit_on_failure?
        true
      end
    end
  end
end
