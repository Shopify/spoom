# typed: strict
# frozen_string_literal: true

require_relative "d3"

require "erb"

module Spoom
  module Coverage
    # @abstract
    class Template
      # Create a new template from an Erb file path
      #: (template: String) -> void
      def initialize(template:)
        @template = template
      end

      #: -> String
      def erb
        File.read(@template)
      end

      #: -> String
      def html
        ERB.new(erb).result(get_binding)
      end

      #: -> Binding
      def get_binding # rubocop:disable Naming/AccessorMethodName
        binding
      end
    end

    # @abstract
    class Page < Template
      TEMPLATE = "#{Spoom::SPOOM_PATH}/templates/page.erb" #: String

      #: String
      attr_reader :title

      #: D3::ColorPalette
      attr_reader :palette

      #: (title: String, palette: D3::ColorPalette, ?template: String) -> void
      def initialize(title:, palette:, template: TEMPLATE)
        super(template: template)
        @title = title
        @palette = palette
      end

      #: -> String
      def header_style
        D3.header_style
      end

      #: -> String
      def header_script
        D3.header_script(palette)
      end

      #: -> String
      def header_html
        "<h1 class='display-3'>#{title}</h1>"
      end

      #: -> String
      def body_html
        cards.map(&:html).join("\n")
      end

      # @abstract
      #: -> Array[Cards::Card]
      def cards = raise NotImplementedError, "Abstract method called"

      #: -> String
      def footer_html
        "Generated by <a href='https://github.com/Shopify/spoom'>spoom</a> on #{Time.now.utc}."
      end
    end

    module Cards
      class Card < Template
        TEMPLATE = "#{Spoom::SPOOM_PATH}/templates/card.erb" #: String

        #: String?
        attr_reader :title, :body

        #: (?template: String, ?title: String?, ?body: String?) -> void
        def initialize(template: TEMPLATE, title: nil, body: nil)
          super(template: template)
          @title = title
          @body = body
        end
      end

      # @abstract
      class Erb < Card
        #: -> void
        def initialize; end # rubocop:disable Lint/MissingSuper

        # @override
        #: -> String
        def html
          ERB.new(erb).result(get_binding)
        end

        # @abstract
        #: -> String
        def erb = raise NotImplementedError, "Abstract method called"
      end

      class Snapshot < Card
        TEMPLATE = "#{Spoom::SPOOM_PATH}/templates/card_snapshot.erb" #: String

        #: Coverage::Snapshot
        attr_reader :snapshot

        #: (snapshot: Coverage::Snapshot, ?title: String) -> void
        def initialize(snapshot:, title: "Snapshot")
          super(template: TEMPLATE, title: title)
          @snapshot = snapshot
        end

        #: -> D3::Pie::Sigils
        def pie_sigils
          D3::Pie::Sigils.new("pie_sigils", "Sigils", snapshot)
        end

        #: -> D3::Pie::Calls
        def pie_calls
          D3::Pie::Calls.new("pie_calls", "Calls", snapshot)
        end

        #: -> D3::Pie::Sigs
        def pie_sigs
          D3::Pie::Sigs.new("pie_sigs", "Sigs", snapshot)
        end
      end

      class Map < Card
        #: (file_tree: FileTree, nodes_strictnesses: Hash[FileTree::Node, String?], nodes_strictness_scores: Hash[FileTree::Node, Float], ?title: String) -> void
        def initialize(file_tree:, nodes_strictnesses:, nodes_strictness_scores:, title: "Strictness Map")
          super(
            title: title,
            body: D3::CircleMap::Sigils.new(
              "map_sigils",
              file_tree,
              nodes_strictnesses,
              nodes_strictness_scores,
            ).html
          )
        end
      end

      class Timeline < Card
        #: (title: String, timeline: D3::Timeline) -> void
        def initialize(title:, timeline:)
          super(title: title, body: timeline.html)
        end

        class Sigils < Timeline
          #: (snapshots: Array[Coverage::Snapshot], ?title: String) -> void
          def initialize(snapshots:, title: "Sigils Timeline")
            super(title: title, timeline: D3::Timeline::Sigils.new("timeline_sigils", snapshots))
          end
        end

        class Calls < Timeline
          #: (snapshots: Array[Coverage::Snapshot], ?title: String) -> void
          def initialize(snapshots:, title: "Calls Timeline")
            super(title: title, timeline: D3::Timeline::Calls.new("timeline_calls", snapshots))
          end
        end

        class Sigs < Timeline
          #: (snapshots: Array[Coverage::Snapshot], ?title: String) -> void
          def initialize(snapshots:, title: "Signatures Timeline")
            super(title: title, timeline: D3::Timeline::Sigs.new("timeline_sigs", snapshots))
          end
        end

        class RBIs < Timeline
          #: (snapshots: Array[Coverage::Snapshot], ?title: String) -> void
          def initialize(snapshots:, title: "RBIs Timeline")
            super(title: title, timeline: D3::Timeline::RBIs.new("timeline_rbis", snapshots))
          end
        end

        class Versions < Timeline
          #: (snapshots: Array[Coverage::Snapshot], ?title: String) -> void
          def initialize(snapshots:, title: "Sorbet Versions Timeline")
            super(title: title, timeline: D3::Timeline::Versions.new("timeline_versions", snapshots))
          end
        end

        class Runtimes < Timeline
          #: (snapshots: Array[Coverage::Snapshot], ?title: String) -> void
          def initialize(snapshots:, title: "Sorbet Typechecking Time")
            super(title: title, timeline: D3::Timeline::Runtimes.new("timeline_runtimes", snapshots))
          end
        end
      end

      class SorbetIntro < Erb
        #: (?sorbet_intro_commit: String?, ?sorbet_intro_date: Time?) -> void
        def initialize(sorbet_intro_commit: nil, sorbet_intro_date: nil) # rubocop:disable Lint/MissingSuper
          @sorbet_intro_commit = sorbet_intro_commit
          @sorbet_intro_date = sorbet_intro_date
        end

        # @override
        #: -> String
        def erb
          <<~ERB
            <div class="text-center" style="margin-top: 30px">
              Typchecked by Sorbet since <b>#{@sorbet_intro_date&.strftime("%F")}</b>
              (commit <b>#{@sorbet_intro_commit}</b>).
            </div>
          ERB
        end
      end
    end

    class Report < Page
      #: (project_name: String, palette: D3::ColorPalette, snapshots: Array[Snapshot], file_tree: FileTree, nodes_strictnesses: Hash[FileTree::Node, String?], nodes_strictness_scores: Hash[FileTree::Node, Float], ?sorbet_intro_commit: String?, ?sorbet_intro_date: Time?) -> void
      def initialize(
        project_name:,
        palette:,
        snapshots:,
        file_tree:,
        nodes_strictnesses:,
        nodes_strictness_scores:,
        sorbet_intro_commit: nil,
        sorbet_intro_date: nil
      )
        super(title: project_name, palette: palette)
        @project_name = project_name
        @snapshots = snapshots
        @file_tree = file_tree
        @nodes_strictnesses = nodes_strictnesses
        @nodes_strictness_scores = nodes_strictness_scores
        @sorbet_intro_commit = sorbet_intro_commit
        @sorbet_intro_date = sorbet_intro_date
      end

      # @override
      #: -> String
      def header_html
        last = T.must(@snapshots.last)
        <<~ERB
          <h1 class="display-3">
            #{@project_name}
            <span class="badge badge-pill badge-dark" style="font-size: 20%;">#{last.commit_sha}</span>
          </h1>
        ERB
      end

      # @override
      #: -> Array[Cards::Card]
      def cards
        last = T.must(@snapshots.last)
        cards = []
        cards << Cards::Snapshot.new(snapshot: last)
        cards << Cards::Map.new(
          file_tree: @file_tree,
          nodes_strictnesses: @nodes_strictnesses,
          nodes_strictness_scores: @nodes_strictness_scores,
        )
        cards << Cards::Timeline::Sigils.new(snapshots: @snapshots)
        cards << Cards::Timeline::Calls.new(snapshots: @snapshots)
        cards << Cards::Timeline::Sigs.new(snapshots: @snapshots)
        cards << Cards::Timeline::RBIs.new(snapshots: @snapshots)
        cards << Cards::Timeline::Versions.new(snapshots: @snapshots)
        cards << Cards::Timeline::Runtimes.new(snapshots: @snapshots)
        cards << Cards::SorbetIntro.new(
          sorbet_intro_commit: @sorbet_intro_commit,
          sorbet_intro_date: @sorbet_intro_date,
        )
        cards
      end
    end
  end
end
