# typed: true
# frozen_string_literal: true

require 'stringio'

module Spoom
  module Cli
    module Commands
      class Base < Thor
        no_commands do
          def say_error(message, status = "Error")
            status = set_color(status, :red)

            buffer = StringIO.new
            buffer << "#{status}: #{message}"
            buffer << "\n" unless message.end_with?("\n")

            $stderr.print(buffer.string)
            $stderr.flush
          end

          def in_sorbet_project?
            File.file?(Spoom::Config::SORBET_CONFIG)
          end

          def in_sorbet_project!
            unless in_sorbet_project?
              say_error("not in a Sorbet project (no sorbet/config)")
              exit(1)
            end
          end
        end
      end
    end
  end
end
