# typed: strict
# frozen_string_literal: true

require "spoom/sorbet/config"
require "spoom/sorbet/errors"
require "spoom/sorbet/lsp"
require "spoom/sorbet/metrics"
require "spoom/sorbet/sigils"

require "open3"

module Spoom
  module Sorbet
    class Error < StandardError
      extend T::Sig

      class Killed < Error; end
      class Segfault < Error; end

      sig { returns(ExecResult) }
      attr_reader :result

      sig do
        params(
          message: String,
          result: ExecResult,
        ).void
      end
      def initialize(message, result)
        super(message)

        @result = result
      end
    end

    CONFIG_PATH = "sorbet/config"
    GEM_PATH = T.let(Gem::Specification.find_by_name("sorbet-static").full_gem_path, String)
    BIN_PATH = T.let((Pathname.new(GEM_PATH) / "libexec" / "sorbet").to_s, String)

    KILLED_CODE = 137
    SEGFAULT_CODE = 139

    class << self
      extend T::Sig

      # List all files typechecked by Sorbet from its `config`
      sig { params(config: Config, path: String).returns(T::Array[String]) }
      def srb_files(config, path: ".")
        regs = config.ignore.map { |string| Regexp.new(Regexp.escape(string)) }
        exts = config.allowed_extensions.empty? ? [".rb", ".rbi"] : config.allowed_extensions
        Dir.glob((Pathname.new(path) / "**/*{#{exts.join(",")}}").to_s).reject do |f|
          regs.any? { |re| re.match?(f) }
        end.sort
      end

      sig do
        params(
          arg: String,
          path: String,
          capture_err: T::Boolean,
          sorbet_bin: T.nilable(String),
        ).returns(T.nilable(T::Hash[String, Integer]))
      end
      def srb_metrics(*arg, path: ".", capture_err: false, sorbet_bin: nil)
        metrics_file = "metrics.tmp"
        metrics_path = "#{path}/#{metrics_file}"
        T.unsafe(self).srb_tc(
          "--metrics-file",
          metrics_file,
          *arg,
          path: path,
          capture_err: capture_err,
          sorbet_bin: sorbet_bin,
        )
        if File.exist?(metrics_path)
          metrics = Spoom::Sorbet::MetricsParser.parse_file(metrics_path)
          File.delete(metrics_path)
          return metrics
        end
        nil
      end
    end
  end
end
