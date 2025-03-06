# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Model
    class NamespaceVisitorTest < Minitest::Test
      class NamespacesForLocs < NamespaceVisitor
        #: Hash[String, String]
        attr_reader :namespaces_for_locs

        #: -> void
        def initialize
          super()
          @namespaces_for_locs = T.let({}, T::Hash[String, String])
        end

        # @override
        #: (Prism::ClassNode node) -> void
        def visit_class_node(node)
          @namespaces_for_locs[loc_string(node.location)] = @names_nesting.join("::")
          super
        end

        # @override
        #: (Prism::ModuleNode node) -> void
        def visit_module_node(node)
          @namespaces_for_locs[loc_string(node.location)] = @names_nesting.join("::")
          super
        end

        private

        #: (Prism::Location loc) -> String
        def loc_string(loc)
          Location.from_prism("-", loc).to_s
        end
      end

      def test_visit_empty
        namespaces = namespaces_for_locs("")
        assert_empty(namespaces)
      end

      def test_visit_classes
        namespaces = namespaces_for_locs(<<~RB)
          class C1
            class C2; end
            class ::C3; end
            class C4::C5; end
          end

          class ::C6; end
          class C7::C8; end
          class ::C9::C10; end
        RB

        assert_equal(
          {
            "-:1:0-5:3" => "C1",
            "-:2:2-2:15" => "C1::C2",
            "-:3:2-3:17" => "C3",
            "-:4:2-4:19" => "C1::C4::C5",
            "-:7:0-7:15" => "C6",
            "-:8:0-8:17" => "C7::C8",
            "-:9:0-9:20" => "C9::C10",
          },
          namespaces,
        )
      end

      def test_visit_modules
        namespaces = namespaces_for_locs(<<~RB)
          module M1
            module M2; end
            module ::M3; end
            module M4::M5; end
          end

          module ::M6; end
          module M7::M8; end
          module ::M9::M10; end
        RB

        assert_equal(
          {
            "-:1:0-5:3" => "M1",
            "-:2:2-2:16" => "M1::M2",
            "-:3:2-3:18" => "M3",
            "-:4:2-4:20" => "M1::M4::M5",
            "-:7:0-7:16" => "M6",
            "-:8:0-8:18" => "M7::M8",
            "-:9:0-9:21" => "M9::M10",
          },
          namespaces,
        )
      end

      private

      #: (String rb) -> Hash[String, String]
      def namespaces_for_locs(rb)
        node = Spoom.parse_ruby(rb, file: "foo.rb")

        visitor = NamespacesForLocs.new
        visitor.visit(node)
        visitor.namespaces_for_locs
      end
    end
  end
end
