# typed: strict
# frozen_string_literal: true

module Spoom
  module Coverage
    module D3
      # @abstract
      class Base
        #: String
        attr_reader :id

        #: (String id, untyped data) -> void
        def initialize(id, data)
          @id = id
          @data = data
        end

        class << self
          #: -> String
          def header_style
            ""
          end

          #: -> String
          def header_script
            ""
          end
        end

        #: -> String
        def html
          <<~HTML
            <svg id="#{id}"></svg>
            <script>#{script}</script>
          HTML
        end

        #: -> String
        def tooltip
          ""
        end

        # @abstract
        #: -> String
        def script = raise NotImplementedError, "Abstract method called"
      end
    end
  end
end
