# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    module Translate
      class StripSorbetSigsTest < Minitest::Test
        def test_strip_sorbet_sigs_empty
          contents = ""
          assert_equal(contents, strip_sorbet_sigs(contents))
        end

        def test_strip_sorbet_sigs_no_sigs
          contents = <<~RB
            class A
              def foo; end
            end
          RB

          assert_equal(contents, strip_sorbet_sigs(contents))
        end

        def test_strip_sorbet_sigs_sigs
          contents = <<~RB
            class A
              sig { returns(Integer) }
              attr_accessor :a

              sig { void }
              def foo; end

              module B
                sig { void }
                sig { returns(Integer) }
                def bar; end
              end
            end
          RB

          assert_equal(<<~RB, strip_sorbet_sigs(contents))
            class A
              attr_accessor :a

              def foo; end

              module B
                def bar; end
              end
            end
          RB
        end

        private

        #: (String) -> String
        def strip_sorbet_sigs(ruby_contents)
          Translate.strip_sorbet_sigs(ruby_contents, file: "test.rb")
        end
      end
    end
  end
end
