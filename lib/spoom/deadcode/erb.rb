# typed: true
# frozen_string_literal: true

module Spoom
  module Deadcode
    # Custom engine to handle ERB templates as used by Rails.
    # Copied from https://github.com/rails/rails/blob/main/actionview/lib/action_view/template/handlers/erb/erubi.rb.
    class ERB < ::Erubi::Engine
      extend T::Sig

      sig { params(input: T.untyped, properties: T.untyped).void }
      def initialize(input, properties = {})
        @newline_pending = 0

        properties = Hash[properties]
        properties[:bufvar]     ||= "@output_buffer"
        properties[:preamble]   ||= ""
        properties[:postamble]  ||= "#{properties[:bufvar]}.to_s"
        properties[:escapefunc] = ""

        super
      end

      private

      sig { params(text: T.untyped).void }
      def add_text(text)
        return if text.empty?

        if text == "\n"
          @newline_pending += 1
        else
          src << bufvar << ".safe_append='"
          src << "\n" * @newline_pending if @newline_pending > 0
          src << text.gsub(/['\\]/, '\\\\\&')
          src << "'.freeze;"

          @newline_pending = 0
        end
      end

      BLOCK_EXPR = /\s*((\s+|\))do|\{)(\s*\|[^|]*\|)?\s*\Z/

      sig { params(indicator: T.untyped, code: T.untyped).void }
      def add_expression(indicator, code)
        flush_newline_if_pending(src)

        src << bufvar << if (indicator == "==") || @escape
          ".safe_expr_append="
        else
          ".append="
        end

        if BLOCK_EXPR.match?(code)
          src << " " << code
        else
          src << "(" << code << ");"
        end
      end

      sig { params(code: T.untyped).void }
      def add_code(code)
        flush_newline_if_pending(src)
        super
      end

      sig { params(_: T.untyped).void }
      def add_postamble(_)
        flush_newline_if_pending(src)
        super
      end

      sig { params(src: T.untyped).void }
      def flush_newline_if_pending(src)
        if @newline_pending > 0
          src << bufvar << ".safe_append='#{"\n" * @newline_pending}'.freeze;"
          @newline_pending = 0
        end
      end
    end
  end
end
