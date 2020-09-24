# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class MetricsTest < Minitest::Test
      def test_parses_metrics_error
        assert_raises JSON::ParserError do
          Spoom::Sorbet::Metrics.parse_string("")
        end
      end

      def test_parses_metrics
        metrics = Spoom::Sorbet::Metrics.parse_string(<<~ERR)
          {
           "repo": "MyRepo",
           "sha": "1234",
           "status": "Success",
           "branch": "master",
           "timestamp": "1594762766",
           "uuid": "some-uuid",
           "metrics": [
            {
             "name": "ruby_typer.unknown..error.total",
             "value": 1
            },
            {
             "name": "ruby_typer.unknown..types.input.sends.total",
             "value": 2094
            }
           ]
          }
        ERR
        assert_equal("MyRepo", metrics.repo)
        assert_equal("1234", metrics.sha)
        assert_equal("master", metrics.branch)
        assert_equal("Success", metrics.status)
        assert_equal(1, metrics["error.total"])
        assert_equal(2094, metrics["types.input.sends.total"])
      end

      def test_parses_metrics_and_removes_prefix
        metrics = Spoom::Sorbet::Metrics.parse_string(<<~ERR, "metrics.")
          {
           "repo": "MyRepo",
           "sha": "1234",
           "status": "Success",
           "branch": "master",
           "timestamp": "1594762766",
           "uuid": "some-uuid",
           "metrics": [
            {
             "name": "metrics.error.total",
             "value": 1
            },
            {
             "name": "metrics.types.input.sends.total",
             "value": 2094
            }
           ]
          }
        ERR
        assert_equal("MyRepo", metrics.repo)
        assert_equal("1234", metrics.sha)
        assert_equal("master", metrics.branch)
        assert_equal("Success", metrics.status)
        assert_equal(1, metrics["error.total"])
        assert_equal(2094, metrics["types.input.sends.total"])
      end

      def test_show_metrics
        metrics = Spoom::Sorbet::Metrics.parse_string(<<~ERR, "metrics.")
          {
           "repo": "MyRepo",
           "sha": "1234",
           "status": "Success",
           "branch": "master",
           "timestamp": "1594762766",
           "uuid": "some-uuid",
           "metrics": [
            {
             "name": "metrics.types.input.files.sigil.true",
             "value": 2
            },
            {
             "name": "metrics.types.input.files.sigil.false",
             "value": 3
            },
            {
             "name": "metrics.types.input.methods.total",
             "value": 10
            },
            {
             "name": "metrics.types.input.classes.total",
             "value": 20
            },
            {
             "name": "metrics.types.input.modules.total",
             "value": 15
            },
            {
             "name": "metrics.types.sig.count",
             "value": 1
            },
            {
             "name": "metrics.types.input.sends.total",
             "value": 100
            },
            {
             "name": "metrics.types.input.sends.typed",
             "value": 10
            }
           ]
          }
        ERR
        out = StringIO.new
        metrics.show(out)
        assert_equal(<<~OUT, out.string)
          Sigils:
            files: 5
            false: 3 (60%)
            true: 2 (40%)

          Classes & Modules:
            classes: 20 (including singleton classes)
            modules: 15

          Methods:
            methods: 10
            signatures: 1 (10%)

          Sends:
            sends: 100
            typed: 10 (10%)
        OUT
      end

      def test_show_metrics_with_0s
        metrics = Spoom::Sorbet::Metrics.parse_string(<<~ERR, "metrics.")
          {
           "repo": "MyRepo",
           "sha": "1234",
           "status": "Success",
           "branch": "master",
           "timestamp": "1594762766",
           "uuid": "some-uuid",
           "metrics": [
            {
             "name": "metrics.types.input.files.sigil.true",
             "value": 0
            },
            {
             "name": "metrics.types.input.files.sigil.false",
             "value": 0
            },
            {
             "name": "metrics.types.input.methods.total",
             "value": 0
            },
            {
             "name": "metrics.types.sig.count",
             "value": 0
            },
            {
             "name": "metrics.types.input.sends.total",
             "value": 0
            },
            {
             "name": "metrics.types.input.sends.typed",
             "value": 0
            }
           ]
          }
        ERR
        out = StringIO.new
        metrics.show(out)
        assert_equal(<<~OUT, out.string)
          Sigils:
            files: 0

          Classes & Modules:
            classes: 0 (including singleton classes)
            modules: 0

          Methods:
            methods: 0
            signatures: 0

          Sends:
            sends: 0
            typed: 0
        OUT
      end
    end
  end
end
