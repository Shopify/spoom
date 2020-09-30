# typed: strict
# frozen_string_literal: true

require_relative "sigils"

module Spoom
  module Sorbet
    module MetricsParser
      extend T::Sig

      DEFAULT_PREFIX = "ruby_typer.unknown.."

      sig { params(path: String, prefix: String).returns(T::Hash[String, Integer]) }
      def self.parse_file(path, prefix = DEFAULT_PREFIX)
        parse_string(File.read(path), prefix)
      end

      sig { params(string: String, prefix: String).returns(T::Hash[String, Integer]) }
      def self.parse_string(string, prefix = DEFAULT_PREFIX)
        parse_hash(JSON.parse(string), prefix)
      end

      sig { params(obj: T::Hash[String, T.untyped], prefix: String).returns(T::Hash[String, Integer]) }
      def self.parse_hash(obj, prefix = DEFAULT_PREFIX)
        obj["metrics"].each_with_object(Hash.new(0)) do |metric, metrics|
          name = metric["name"]
          name = name.sub(prefix, '')
          metrics[name] = metric["value"] || 0
        end
      end
    end
  end
end
