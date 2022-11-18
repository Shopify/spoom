# typed: strict
# frozen_string_literal: true

require_relative "coverage/snapshot"
require_relative "coverage/report"
require_relative "file_tree"

require "date"

module Spoom
  module Coverage
    class << self
      extend T::Sig

      sig { params(path: String, rbi: T::Boolean, sorbet_bin: T.nilable(String)).returns(Snapshot) }
      def snapshot(path: ".", rbi: true, sorbet_bin: nil)
        config = sorbet_config(path: path)
        config.allowed_extensions.push(".rb", ".rbi") if config.allowed_extensions.empty?

        new_config = config.copy
        new_config.allowed_extensions.reject! { |ext| !rbi && ext == ".rbi" }
        flags = [
          "--no-config",
          "--no-error-sections",
          "--no-error-count",
          "--isolate-error-code=0",
          new_config.options_string,
        ]

        metrics = Spoom::Sorbet.srb_metrics(
          *flags,
          path: path,
          capture_err: true,
          sorbet_bin: sorbet_bin,
        )
        # Collect extra information using a different configuration
        flags << "--ignore sorbet/rbi/"
        metrics_without_rbis = Spoom::Sorbet.srb_metrics(
          *flags,
          path: path,
          capture_err: true,
          sorbet_bin: sorbet_bin,
        )

        snapshot = Snapshot.new
        return snapshot unless metrics

        last_commit = Spoom::Git.last_commit(path: path)
        snapshot.commit_sha = last_commit&.sha
        snapshot.commit_timestamp = last_commit&.timestamp

        snapshot.files = metrics.fetch("types.input.files", 0)
        snapshot.modules = metrics.fetch("types.input.modules.total", 0)
        snapshot.classes = metrics.fetch("types.input.classes.total", 0)
        snapshot.singleton_classes = metrics.fetch("types.input.singleton_classes.total", 0)
        snapshot.methods_with_sig = metrics.fetch("types.sig.count", 0)
        snapshot.methods_without_sig = metrics.fetch("types.input.methods.total", 0) - snapshot.methods_with_sig
        snapshot.calls_typed = metrics.fetch("types.input.sends.typed", 0)
        snapshot.calls_untyped = metrics.fetch("types.input.sends.total", 0) - snapshot.calls_typed

        snapshot.duration += metrics.fetch("run.utilization.system_time.us", 0)
        snapshot.duration += metrics.fetch("run.utilization.user_time.us", 0)

        if metrics_without_rbis
          snapshot.methods_with_sig_excluding_rbis = metrics_without_rbis.fetch("types.sig.count", 0)
          snapshot.methods_without_sig_excluding_rbis = metrics_without_rbis.fetch("types.input.methods.total",
            0) - snapshot.methods_with_sig_excluding_rbis
        end

        Snapshot::STRICTNESSES.each do |strictness|
          if metrics.key?("types.input.files.sigil.#{strictness}")
            snapshot.sigils[strictness] = T.must(metrics["types.input.files.sigil.#{strictness}"])
          end
          if metrics_without_rbis&.key?("types.input.files.sigil.#{strictness}")
            snapshot.sigils_excluding_rbis[strictness] =
              T.must(metrics_without_rbis["types.input.files.sigil.#{strictness}"])
          end
        end

        snapshot.version_static = Spoom::Sorbet.version_from_gemfile_lock(gem: "sorbet-static", path: path)
        snapshot.version_runtime = Spoom::Sorbet.version_from_gemfile_lock(gem: "sorbet-runtime", path: path)

        files = Spoom::Sorbet.srb_files(new_config, path: path)
        snapshot.rbi_files = files.count { |file| file.end_with?(".rbi") }

        snapshot
      end

      sig { params(snapshots: T::Array[Snapshot], palette: D3::ColorPalette, path: String).returns(Report) }
      def report(snapshots, palette:, path: ".")
        intro_commit = Git.sorbet_intro_commit(path: path)

        Report.new(
          project_name: File.basename(File.expand_path(path)),
          palette: palette,
          snapshots: snapshots,
          sigils_tree: sigils_tree(path: path),
          sorbet_intro_commit: intro_commit&.sha,
          sorbet_intro_date: intro_commit&.time,
        )
      end

      sig { params(path: String).returns(Sorbet::Config) }
      def sorbet_config(path: ".")
        Sorbet::Config.parse_file("#{path}/#{Spoom::Sorbet::CONFIG_PATH}")
      end

      sig { params(path: String).returns(FileTree) }
      def sigils_tree(path: ".")
        config = sorbet_config(path: path)
        files = Sorbet.srb_files(config, path: path)

        extensions = config.allowed_extensions
        extensions = [".rb"] if extensions.empty?
        extensions -= [".rbi"]

        pattern = /\.(#{Regexp.union(extensions.map { |ext| ext[1..-1] })})$/
        files.select! { |file| file =~ pattern }
        files.reject! { |file| file =~ %r{/test/} }

        FileTree.new(files, strip_prefix: path)
      end
    end
  end
end
