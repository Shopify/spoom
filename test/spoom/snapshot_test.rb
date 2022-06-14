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
        snapshot1.rbi_files = 1
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
        assert_equal(1, snapshot2.rbi_files)
        assert_equal(10, snapshot2.sigils["true"])
      end

      def test_snapshot_project
        project = self.project
        snapshot = Spoom::Coverage.snapshot(path: project.path)
        assert_equal(4, snapshot.files)
        assert_equal(1, snapshot.rbi_files)
        assert_equal({ "false" => 1, "true" => 3 }, snapshot.sigils)
        assert_equal(5, snapshot.modules)
        assert_equal(9, snapshot.classes)
        assert_equal(1, snapshot.methods_with_sig)
        assert_equal(13, snapshot.methods_without_sig)
        assert_equal(6, snapshot.calls_typed)
        assert_equal(1, snapshot.calls_untyped)
        project.destroy
      end

      def test_snapshot_project_without_rbi
        project = self.project
        snapshot = Spoom::Coverage.snapshot(path: project.path, rbi: false)
        assert_equal(3, snapshot.files)
        assert_equal(0, snapshot.rbi_files)
        assert_equal({ "false" => 1, "true" => 2 }, snapshot.sigils)
        assert_equal(3, snapshot.modules)
        assert_equal(5, snapshot.classes)
        assert_equal(1, snapshot.methods_with_sig)
        assert_equal(8, snapshot.methods_without_sig)
        assert_equal(6, snapshot.calls_typed)
        assert_equal(1, snapshot.calls_untyped)
        project.destroy
      end

      def project
        project = spoom_project
        project.sorbet_config(<<~CONFIG)
          .
          --allowed-extension .rb
          --allowed-extension .rbi
        CONFIG
        project.write("lib/a.rb", <<~RB)
          # typed: false

          module A1; end
          module A2; end

          class A3
            def foo; end
          end
        RB
        project.write("lib/b.rb", <<~RB)
          # typed: true

          module B1
            extend T::Sig

            sig { void }
            def self.foo; end
          end
        RB
        project.write("lib/c.rb", <<~RB)
          # typed: true
          A3.new.foo
          B1.foo
        RB
        project.write("lib/d.rbi", <<~RB)
          # typed: true

          module D1; end
          module D2; end

          class D3
            def foo; end
          end
        RB
        project
      end
    end
  end
end
