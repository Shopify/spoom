# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  module Sorbet
    class SnapshotTest < Minitest::Test
      include Spoom::TestHelper

      def test_serialize_snapshot_empty
        snapshot1 = Spoom::Coverage::Snapshot.new
        json1 = snapshot1.to_json

        snapshot2 = Spoom::Coverage::Snapshot.from_json(json1)
        json2 = snapshot2.to_json

        assert_equal(json1, json2)
      end

      def test_serialize_snapshot_data
        snapshot1 = Spoom::Coverage::Snapshot.new
        snapshot1.version_static = "sorbet_version"
        snapshot1.commit_sha = "commit_sha"
        snapshot1.commit_timestamp = 1
        snapshot1.files = 2
        snapshot1.modules = 3
        snapshot1.classes = 4
        snapshot1.methods_with_sig = 5
        snapshot1.methods_without_sig = 6
        snapshot1.calls_typed = 7
        snapshot1.calls_untyped = 8
        snapshot1.sigils = { "true" => 10 }
        json1 = snapshot1.to_json

        snapshot2 = Spoom::Coverage::Snapshot.from_json(json1)
        json2 = snapshot2.to_json

        assert_equal(json1, json2)
        assert_equal("sorbet_version", snapshot2.version_static)
        assert_equal(2, snapshot2.files)
        assert_equal(10, snapshot2.sigils["true"])
      end
    end
  end
end
