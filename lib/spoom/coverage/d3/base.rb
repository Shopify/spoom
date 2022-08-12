# typed: strict
# frozen_string_literal: true

module Spoom
  module Coverage
    module D3
      class Base
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { returns(String) }
        attr_reader :id

        sig { params(id: String, data: T.untyped).void }
        def initialize(id, data)
          @id = id
          @data = data
        end

        class << self
          extend T::Sig

          sig { returns(String) }
          def header_style
            ""
          end

          sig { returns(String) }
          def header_script
            ""
          end
        end

        sig { returns(String) }
        def html
          <<~HTML
            <svg id="#{id}"></svg>
            <script>#{script}</script>
          HTML
        end

        sig { returns(String) }
        def tooltip
          ""
        end

        sig { abstract.returns(String) }
        def script; end
      end
    end
  end
end
