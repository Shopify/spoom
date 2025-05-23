# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    module Metrics
      class CodeMetricsVisitorTest < Minitest::Test
        def test_collects_base_metrics
          metrics = collect_metrics do |context|
            context.write!("foo.rb", <<~RUBY)
              class Foo
                attr_accessor :foo

                def initialize; end
              end
            RUBY

            context.write!("bar.rb", <<~RUBY)
              module Bar
                class << self
                  def bar; end
                end
              end
            RUBY
          end

          assert_equal(2, metrics["files"])
          assert_equal(1, metrics["classes"])
          assert_equal(1, metrics["modules"])
          assert_equal(1, metrics["singleton_classes"])
          assert_equal(2, metrics["methods"])
          assert_equal(1, metrics["accessors"])
        end

        def test_collects_metrics_about_sigs
          metrics = collect_metrics do |context|
            context.write!("foo.rb", <<~RUBY)
              class Foo
                #: Foo
                attr_accessor :a1

                sig { returns(String) }
                attr_reader :a2

                attr_writer :a3

                #: -> void
                def initialize; end

                sig { abstract.returns(Integer) }
                def m1; end

                def m2; end

                def test_is_ignored_because_it_starts_with_test_; end
              end
            RUBY
          end

          assert_equal(3, metrics["methods"])
          assert_equal(1, metrics["methods_without_sig"])
          assert_equal(1, metrics["methods_with_srb_sig"])
          assert_equal(1, metrics["methods_with_rbs_sig"])
          assert_equal(3, metrics["accessors"])
          assert_equal(1, metrics["accessors_without_sig"])
          assert_equal(1, metrics["accessors_with_srb_sig"])
          assert_equal(1, metrics["accessors_with_rbs_sig"])

          assert_equal(2, metrics["srb_sigs"])
          assert_equal(1, metrics["srb_sigs_abstract"])
        end

        def test_collects_metrics_about_generics
          metrics = collect_metrics do |context|
            context.write!("foo.rb", <<~RUBY)
              class Foo
                E = type_member
                F = type_template
              end

              #: [E, F]
              class Bar
              end
            RUBY
          end

          assert_equal(1, metrics["type_members"])
          assert_equal(1, metrics["type_templates"])
          assert_equal(1, metrics["classes_with_rbs_type_params"])
          assert_equal(1, metrics["classes_with_srb_type_params"])
        end

        def test_collects_metrics_about_calls
          metrics = collect_metrics do |context|
            context.write!("foo.rb", <<~RUBY)
              x = T.let(1, T.nilable(Integer))
              T.must(x)
            RUBY
          end

          assert_equal(3, metrics["calls"])
          assert_equal(3, metrics["T_calls"])
          assert_equal(1, metrics["T.must"])
          assert_equal(1, metrics["T.let"])
          assert_equal(1, metrics["T.nilable"])
        end

        def test_collects_metrics_about_RBS_assertions
          metrics = collect_metrics do |context|
            context.write!("foo.rb", <<~RUBY)
              x = 1 #: Integer
              x = 1 #: as !nil
              x = 1 #: as untyped
              x = 1 #: as Integer
            RUBY
          end

          assert_equal(4, metrics["rbs_assertions"])
          assert_equal(1, metrics["rbs_let"])
          assert_equal(1, metrics["rbs_must"])
          assert_equal(1, metrics["rbs_unsafe"])
          assert_equal(1, metrics["rbs_cast"])
        end

        private

        #: { (Context) -> void } -> Counters
        def collect_metrics(&block)
          context = Context.mktmp!
          block.call(context)

          files = Dir["#{context.absolute_path}/**/*.rb"]
          metrics = Spoom::Sorbet::Metrics.collect_code_metrics(files)
          context.destroy!

          metrics
        end
      end
    end
  end
end
