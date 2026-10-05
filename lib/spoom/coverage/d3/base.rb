# typed: strict
# frozen_string_literal: true

module Spoom
  module Coverage
    module D3
      # @abstract
      class Base
        # Characters that must not appear raw inside a `<script>` element, and their JSON string escapes
        JS_LITERAL_ESCAPES = { "<" => '\u003c', ">" => '\u003e', "&" => '\u0026' }.freeze #: Hash[String, String]

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
        def script = super

        private

        # Serialize `value` as a JavaScript literal that is safe to embed in a `<script>` tag
        #
        # `script_safe` escapes `/` so the data can't contain `</script>`. We also escape `<`, `>` and `&`
        # so the data can't contain `<!--` or `<script`, which change how the HTML parser reads the rest
        # of the `<script>` element.
        #: (untyped value) -> String
        def js_literal(value)
          JSON.generate(value, script_safe: true).gsub(/[<>&]/, JS_LITERAL_ESCAPES)
        end
      end
    end
  end
end
