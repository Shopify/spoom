# typed: strict
# frozen_string_literal: true

require "spoom/sorbet/sigils"

module Spoom
  module Sorbet
    module Metrics
      module MetricsFileParser
        DEFAULT_PREFIX = "ruby_typer.unknown."

        class << self
          # Raises if `path` doesn't point to a valid file that we have access to (see `File.read` for details)
          #: (String path, ?String prefix) -> Hash[String, Integer]
          def parse_file(path, prefix = DEFAULT_PREFIX)
            parse_string(File.read(path), prefix)
          end

          #: (String string, ?String prefix) -> Hash[String, Integer]
          def parse_string(string, prefix = DEFAULT_PREFIX)
            parse_hash(JSON.parse(string), prefix)
          end

          #: (Hash[String, untyped] obj, ?String prefix) -> Counters
          def parse_hash(obj, prefix = DEFAULT_PREFIX)
            obj["metrics"].each_with_object(Counters.new) do |metric, metrics|
              name = metric["name"].sub(prefix, "")
              metrics[name] = metric["value"] || 0
            end
          end
        end
      end
    end
  end
end
