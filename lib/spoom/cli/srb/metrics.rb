# typed: true
# frozen_string_literal: true

module Spoom
  module Cli
    module Srb
      class Metrics < Thor
        include Helper

        default_task :show

        desc "show", "Show metrics about Sorbet usage"
        option :dump, type: :boolean, default: false
        def show(*paths)
          files = collect_files(paths)
          metrics = Spoom::Sorbet::Metrics.collect_code_metrics(files)

          if options[:dump]
            metrics.sort_by { |key, _value| key }.each do |key, value|
              puts "#{key} #{value}"
            end

            return
          end

          say("Files: `#{files.size}`")

          ["classes", "modules", "singleton_classes"].each do |key|
            value = metrics[key]
            next if value == 0

            say("\n#{key.capitalize}: `#{value}`")
            ["with_srb_type_params", "with_rbs_type_params"].each do |subkey|
              say(" * #{subkey.gsub("_", " ")}: `#{metrics["#{key}_#{subkey}"]}`")
            end
          end

          ["methods", "accessors"].each do |key|
            value = metrics[key]
            next if value == 0

            say("\n#{key.capitalize}: `#{value}`")
            ["without_sig", "with_srb_sig", "with_rbs_sig"].each do |subkey|
              say(" * #{subkey.gsub("_", " ")}: `#{metrics["#{key}_#{subkey}"]}`")
            end
          end

          say("\nT. calls: `#{metrics["T_calls"]}`")
          metrics
            .select { |key, _value| key.start_with?("T.") }
            .sort_by { |_key, value| -value }
            .each do |key, value|
              say(" * #{key}: `#{value}`")
            end

          say("\nRBS Assertions: `#{metrics["rbs_assertions"]}`")
          metrics
            .reject { |key, _value| key == "rbs_assertions" }
            .select { |key, _value| key.start_with?("rbs_") }
            .sort_by { |_key, value| -value }
            .each do |key, value|
            say(" * #{key}: `#{value}`")
          end
        end
      end
    end
  end
end
