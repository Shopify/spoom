# typed: true
# frozen_string_literal: true

require_relative "../file_tree"
require_relative "../sorbet/config"

module Spoom
  module Cli
    module Commands
      class Config < Thor
        include Helper

        default_task :show

        desc "show", "show Sorbet config"
        def show
          in_sorbet_project!
          config = Spoom::Sorbet::Config.parse_file(sorbet_config)

          say("Found Sorbet config at `#{sorbet_config}`.")

          say("\nPaths typechecked:")
          if config.paths.empty?
            say(" * (default: .)")
          else
            config.paths.each do |path|
              say(" * #{path}")
            end
          end

          say("\nPaths ignored:")
          if config.ignore.empty?
            say(" * (default: none)")
          else
            config.ignore.each do |path|
              say(" * #{path}")
            end
          end

          say("\nAllowed extensions:")
          if config.allowed_extensions.empty?
            say(" * .rb (default)")
            say(" * .rbi (default)")
          else
            config.allowed_extensions.each do |ext|
              say(" * #{ext}")
            end
          end
        end
      end
    end
  end
end
