# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class MetricsTest < Minitest::Test
      def test_parses_metrics_error
        assert_raises JSON::ParserError do
          Spoom::Sorbet::MetricsParser.parse_string("")
        end
      end

      def test_parses_metrics
        metrics = Spoom::Sorbet::MetricsParser.parse_string(<<~ERR)
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
        assert_equal(1, metrics["error.total"])
        assert_equal(2094, metrics["types.input.sends.total"])
      end

      def test_parses_metrics_and_removes_prefix
        metrics = Spoom::Sorbet::MetricsParser.parse_string(<<~ERR, "metrics.")
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
        assert_equal(1, metrics["error.total"])
        assert_equal(2094, metrics["types.input.sends.total"])
      end
    end
  end
end
