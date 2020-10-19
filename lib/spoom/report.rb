# typed: strict
# frozen_string_literal: true

require_relative "file_tree"
require_relative "snapshot"
require_relative "coverage/report"

require "date"

module Spoom
  module Coverage
    extend T::Sig

    sig { params(snapshots: T::Array[Snapshot], path: String).returns(Report) }
    def self.report(snapshots, path: ".")
      intro_commit = Git.sorbet_intro_commit(path: path)
      intro_date = intro_commit ? Git.commit_time(intro_commit, path: path) : nil

      Report.new(
        project_name: File.basename(File.expand_path(path)),
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
      FileTree.new(files)
    end

    class Report < Page
      extend T::Sig

      sig { returns(String) }
      attr_reader :project_name

      sig { returns(T.nilable(String)) }
      attr_reader :sorbet_intro_commit

      sig { returns(T.nilable(Time)) }
      attr_reader :sorbet_intro_date

      sig { returns(T::Array[Snapshot]) }
      attr_reader :snapshots

      sig { returns(FileTree) }
      attr_reader :sigils_tree

      sig do
        params(
          project_name: String,
          snapshots: T::Array[Snapshot],
          sigils_tree: FileTree,
          sorbet_intro_commit: T.nilable(String),
          sorbet_intro_date: T.nilable(Time),
        ).void
      end
      def initialize(project_name:, snapshots:, sigils_tree:, sorbet_intro_commit: nil, sorbet_intro_date: nil)
        super(title: project_name)
        @project_name = project_name
        @snapshots = snapshots
        @sigils_tree = sigils_tree
        @sorbet_intro_commit = sorbet_intro_commit
        @sorbet_intro_date = sorbet_intro_date
      end

      sig { override.returns(String) }
      def header_html
        last = T.must(snapshots.last)
        <<~ERB
          <h1 class="display-3">
            #{project_name}
            <span class="badge badge-pill badge-dark" style="font-size: 20%;">#{last.commit_sha}</span>
          </h1>
        ERB
      end

      sig { override.returns(T::Array[Cards::Card]) }
      def cards
        last = T.must(snapshots.last)
        cards = []
        cards << Cards::Snapshot.new(snapshot: last)
        cards << Cards::Map.new(sigils_tree: sigils_tree)
        cards << Cards::Timeline::Sigils.new(snapshots: snapshots)
        cards << Cards::Timeline::Calls.new(snapshots: snapshots)
        cards << Cards::Timeline::Sigs.new(snapshots: snapshots)
        cards << Cards::Timeline::Versions.new(snapshots: snapshots)
        cards << Cards::Timeline::Runtimes.new(snapshots: snapshots)
        cards << Cards::SorbetIntro.new(sorbet_intro_commit: sorbet_intro_commit, sorbet_intro_date: sorbet_intro_date)
        cards
      end
    end
  end
end
