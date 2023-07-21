# typed: strict
# frozen_string_literal: true

module Spoom
  class Model
    class GraphPrinter < Printer
      extend T::Sig

      sig { returns(String) }
      attr_reader :out

      sig { params(model: Model).void }
      def initialize(model)
        super()

        @model = model
        indent
      end

      sig { override.params(symbol: Ref).void }
      def visit_ref(symbol)
        printl("\"#{symbol.full_name}\"")
      end

      sig { override.params(symbol: Class).void }
      def visit_class(symbol)
        printl("\"#{symbol.full_name}\"")

        superclass = symbol.superclass
        if superclass
          printl("\"#{symbol.full_name}\" -> \"#{superclass.full_name}\"")
        else
          printl("\"#{symbol.full_name}\" -> \"Object\"")
        end
        symbol.includes.each do |mod|
          printl("\"#{symbol.full_name}\" -> \"#{mod.full_name}\" [style=dashed]")
        end
      end

      sig { override.params(symbol: Module).void }
      def visit_module(symbol)
        printl("\"#{symbol.full_name}\"")

        symbol.includes.each do |mod|
          printl("\"#{symbol.full_name}\" -> \"#{mod.full_name}\"")
        end
      end

      # Properties

      sig { override.params(symbol: Attr).void }
      def visit_attr(symbol)
        # printl("# #{symbol.location}")
        # printl("#{symbol.kind} #{symbol.name}")
      end

      sig { override.params(symbol: Method).void }
      def visit_method(symbol)
        # printl("# #{symbol.location}")
        # printl("def #{symbol.name}; end")
      end

      sig { override.params(symbol: Prop).void }
      def visit_prop(symbol)
        # printl("# #{symbol.location}")
        # printt
        # if symbol.read_only
        #   print("const")
        # else
        #   print("prop")
        # end
        # printn(" #{symbol.name}, type: \"#{symbol.type}\"")
      end

      sig { returns(String) }
      def graph
        puts out
        <<~DOT
          digraph hierarchy {
            rankdir="BT"
            splines=ortho
            node [
              fontname="Helvetica,Arial,sans-serif"
              shape=record
              style=filled
              fillcolor=gray95
            ]
            #{out}
          }
        DOT
      end
    end
  end
end
