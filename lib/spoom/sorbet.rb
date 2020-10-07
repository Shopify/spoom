# typed: true
# frozen_string_literal: true

require "spoom/sorbet/config"
require "spoom/sorbet/errors"
require "spoom/sorbet/lsp"
require "spoom/sorbet/metrics"
require "spoom/sorbet/sigils"

require "open3"

module Spoom
  module Sorbet
    extend T::Sig

    sig { params(arg: String, path: String, capture_err: T::Boolean).returns([String, T::Boolean]) }
    def self.srb(*arg, path: '.', capture_err: false)
      opts = {}
      opts[:chdir] = path
      out = T.let("", T.nilable(String))
      res = T.let(false, T::Boolean)
      if capture_err
        Open3.popen2e(["bundle", "exec", "srb", *arg].join(" "), opts) do |_, o, t|
          out = o.read
          res = T.cast(t.value, Process::Status).success?
        end
      else
        Open3.popen2(["bundle", "exec", "srb", *arg].join(" "), opts) do |_, o, t|
          out = o.read
          res = T.cast(t.value, Process::Status).success?
        end
      end
      [out || "", res]
    end

    sig { params(arg: String, path: String, capture_err: T::Boolean).returns([String, T::Boolean]) }
    def self.srb_tc(*arg, path: '.', capture_err: false)
      srb(*T.unsafe(["tc", *arg]), path: path, capture_err: capture_err)
    end

    # List all files typechecked by Sorbet from its `config`
    sig { params(config: Config, path: String).returns(T::Array[String]) }
    def self.srb_files(config, path: '.')
      regs = config.ignore.map { |string| Regexp.new(Regexp.escape(string)) }
      exts = config.allowed_extensions.empty? ? ['.rb', '.rbi'] : config.allowed_extensions
      Dir.glob((Pathname.new(path) / "**/*{#{exts.join(',')}}").to_s).reject do |f|
        regs.any? { |re| re.match?(f) }
      end.sort
    end

    sig { params(arg: String, path: String, capture_err: T::Boolean).returns(T.nilable(String)) }
    def self.srb_version(*arg, path: '.', capture_err: false)
      out, res = srb(*T.unsafe(["--version", *arg]), path: path, capture_err: capture_err)
      return nil unless res
      out.split(" ")[2]
    end

    # Get `sorbet` version from the `Gemfile.lock` content
    #
    # Returns `nil` if `sorbet` gem cannot be found in the Gemfile.
    sig { params(path: String).returns(T.nilable(String)) }
    def self.srb_version_from_gemfile_lock(path: '.')
      gemfile_path = "#{path}/Gemfile.lock"
      return nil unless File.exist?(gemfile_path)
      gemfile_lock = Bundler.read_file(gemfile_path)
      parser = Bundler::LockfileParser.new(gemfile_lock)
      sorbet = parser.specs.find { |spec| spec.name == "sorbet" }
      return nil unless sorbet
      sorbet.version.to_s
    end

    sig { params(arg: String, path: String, capture_err: T::Boolean).returns(T.nilable(T::Hash[String, Integer])) }
    def self.srb_metrics(*arg, path: '.', capture_err: false)
      metrics_file = "metrics.tmp"
      metrics_path = "#{path}/#{metrics_file}"
      srb_tc(*T.unsafe(["--metrics-file=#{metrics_file}", *arg]), path: path, capture_err: capture_err)
      if File.exist?(metrics_path)
        metrics = Spoom::Sorbet::MetricsParser.parse_file(metrics_path)
        File.delete(metrics_path)
        return metrics
      end
      nil
    end
  end
end
