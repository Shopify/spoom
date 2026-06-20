# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module Translate
      # Checks that a translation preserved the lines of every "landmark" (e.g. classes, method defs, and so on)
      # so line numbers in the rewritten output still line up with the original source.
      module Validator
        # A description of a landmark, like "class C", "def foo", etc.
        #: type landmarkID = String

        # The integer line numbers where each landmark appears.
        #: type landmarks = Hash[landmarkID, Array[Integer]]

        class << self
          # Compares the landmarks in both sources and returns a result describing
          # what changed:
          #   missing_from_rewritten_output - dropped: an occurrence in the original
          #                                   that is gone from the rewrite
          #   excess_in_rewritten_output    - added: an occurrence in the rewrite with
          #                                   no match in the original
          #   on_wrong_line                 - survived but moved to a different line
          #: (String original, String rewritten) -> ValidationResult
          def validate(original, rewritten)
            original_landmarks = LandmarkFinder.find_landmarks_in(original)
            rewritten_landmarks = LandmarkFinder.find_landmarks_in(rewritten)

            missing = []
            excess = []
            on_wrong_line = []

            (original_landmarks.keys | rewritten_landmarks.keys).each do |landmark_id|
              original_lines = original_landmarks.fetch(landmark_id, [])
              rewritten_lines = rewritten_landmarks.fetch(landmark_id, [])

              dropped = original_lines - rewritten_lines
              added = rewritten_lines - original_lines

              if dropped.any? && added.any?
                # Present in both but on different lines: the landmark moved.
                on_wrong_line << { landmark_id:, expected: dropped, actual: added }
              else
                dropped.each { |line| missing << { landmark_id:, line: } }
                added.each { |line| excess << { landmark_id:, line: } }
              end
            end

            if original.lines.count != rewritten.lines.count
              on_wrong_line << { landmark_id: "EOF", expected: [original.lines.count], actual: [rewritten.lines.count] }
            end

            ValidationResult.new(
              missing_from_rewritten_output: missing,
              excess_in_rewritten_output: excess,
              on_wrong_line: on_wrong_line,
            )
          end
        end
      end

      # The outcome of comparing an original source with its rewritten form.
      class ValidationResult
        # A landmark dropped from, or added to, the rewritten output.
        #: type landmark_location = { landmark_id: String, line: Integer }

        # A landmark present in both sources, but on different lines.
        #: type moved_landmark = { landmark_id: String, expected: Array[Integer], actual: Array[Integer] }

        # Landmarks present in the original but missing from the rewrite.
        #: Array[landmark_location]
        attr_reader :missing_from_rewritten_output

        # Landmarks present in the rewrite with no match in the original.
        #: Array[landmark_location]
        attr_reader :excess_in_rewritten_output

        # Landmarks present in both sources, but that moved to a different line.
        #: Array[moved_landmark]
        attr_reader :on_wrong_line

        #: (
        #|   missing_from_rewritten_output: Array[landmark_location],
        #|   excess_in_rewritten_output: Array[landmark_location],
        #|   on_wrong_line: Array[moved_landmark]
        #| ) -> void
        def initialize(missing_from_rewritten_output:, excess_in_rewritten_output:, on_wrong_line:)
          @missing_from_rewritten_output = missing_from_rewritten_output
          @excess_in_rewritten_output = excess_in_rewritten_output
          @on_wrong_line = on_wrong_line
        end

        # True when every landmark survived the rewrite on its original line.
        #: -> bool
        def valid?
          @missing_from_rewritten_output.empty? &&
            @excess_in_rewritten_output.empty? &&
            @on_wrong_line.empty?
        end

        # Human-readable, one-per-line descriptions of every difference. Empty when
        # the result is valid.
        #: -> Array[String]
        def errors
          errors = @missing_from_rewritten_output.map do |entry|
            "missing `#{entry[:landmark_id]}` (expected at line #{entry[:line]})"
          end
          errors += @excess_in_rewritten_output.map do |entry|
            "excess `#{entry[:landmark_id]}` (found at line #{entry[:line]})"
          end
          errors += @on_wrong_line.map do |entry|
            "`#{entry[:landmark_id]}` on the wrong line " \
              "(expected at #{format_lines(entry[:expected])}, found at #{format_lines(entry[:actual])})"
          end
          errors
        end

        private

        #: (Array[Integer]) -> String
        def format_lines(lines)
          "#{lines.size == 1 ? "line" : "lines"} #{lines.join(", ")}"
        end
      end

      # Walks a Prism AST and records the locations of various bits of code
      # whose locations we want to remain constant after a rewriter.
      class LandmarkFinder < Prism::Visitor
        #: Validator::landmarks
        attr_reader :landmarks

        class << self
          #: (String) -> Hash[String, Array[Integer]]
          def find_landmarks_in(source)
            visitor = new
            Prism.parse(source).value.accept(visitor)
            visitor.landmarks
          end
        end

        #: -> void
        def initialize
          super
          @landmarks = Hash.new { |h, landmark_id| h[landmark_id] = [] } #: Validator::landmarks
        end

        # @override
        #: (Prism::ClassNode) -> void
        def visit_class_node(node)
          record("class #{node.name}", node)
          super # keep descending so nested classes/modules/defs are recorded too
        end

        # @override
        #: (Prism::ModuleNode) -> void
        def visit_module_node(node)
          record("module #{node.name}", node)
          super
        end

        # @override
        #: (Prism::SingletonClassNode) -> void
        def visit_singleton_class_node(node)
          # `class << self` (or `class << obj`); record its opening location.
          record("class << #{node.expression.slice}", node)
          super
        end

        # @override
        #: (Prism::DefNode) -> void
        def visit_def_node(node)
          # `def self.foo` (and `def Foo.bar`) carry a receiver; include it so
          # singleton methods read like their source and key separately from
          # same-named instance methods.
          receiver = node.receiver
          receiver_description = receiver ? "#{receiver.slice}." : ""
          record("def #{receiver_description}#{node.name}", node)
          super
        end

        # @override
        #: (Prism::SourceLineNode) -> void
        def visit_source_line_node(node)
          record("__LINE__", node) # its value changes if the line moves
          super
        end

        private

        #: (String landmark_id, Prism::Node) -> void
        def record(landmark_id, node)
          (@landmarks[landmark_id] ||= []) << node.location.start_line
        end
      end
      private_constant :LandmarkFinder
    end
  end
end
