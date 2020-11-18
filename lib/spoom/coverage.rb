# typed: strict
# frozen_string_literal: true

require_relative "coverage/snapshot"
require_relative "coverage/report"
require_relative "file_tree"

require "date"

module Spoom
  module Coverage
    extend T::Sig

    sig { params(path: String).returns(Snapshot) }
    def self.snapshot(path: '.')
      snapshot = Snapshot.new
      metrics = Spoom::Sorbet.srb_metrics(path: path, capture_err: true)
      return snapshot unless metrics

      sha = Spoom::Git.last_commit(path: path)
      snapshot.commit_sha = sha
      snapshot.commit_timestamp = Spoom::Git.commit_timestamp(sha, path: path).to_i if sha

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

      Snapshot::STRICTNESSES.each do |strictness|
        next unless metrics.key?("types.input.files.sigil.#{strictness}")
        snapshot.sigils[strictness] = T.must(metrics["types.input.files.sigil.#{strictness}"])
      end

      snapshot.version_static = Spoom::Sorbet.version_from_gemfile_lock(gem: "sorbet-static", path: path)
      snapshot.version_runtime = Spoom::Sorbet.version_from_gemfile_lock(gem: "sorbet-runtime", path: path)

      snapshot
    end

    sig { params(snapshots: T::Array[Snapshot], palette: D3::ColorPalette, path: String).returns(Report) }
    def self.report(snapshots, palette:, path: ".")
      intro_commit = Git.sorbet_intro_commit(path: path)
      intro_date = intro_commit ? Git.commit_time(intro_commit, path: path) : nil

      Report.new(
        project_name: File.basename(File.expand_path(path)),
        palette: palette,
        snapshots: snapshots,
        sigils_tree: sigils_tree(path: path),
        sorbet_intro_commit: intro_commit,
        sorbet_intro_date: intro_date,
      )
    end

    sig { params(path: String).returns(FileTree) }
    def self.sigils_tree(path: ".")
      config_file = "#{path}/#{Spoom::Config::SORBET_CONFIG}"
      return FileTree.new unless File.exist?(config_file)
      config = Sorbet::Config.parse_file(config_file)
      files = Sorbet.srb_files(config, path: path)
      files.select! { |file| file =~ /\.rb$/ }
      files.reject! { |file| file =~ %r{/test/} }
      FileTree.new(files, strip_prefix: path)
    end
  end
end
