# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class CFGFixturesTest < Minitest::Test
    extend T::Sig

    fixtures_path = File.expand_path("fixtures", __dir__)
    fixture_files = Dir.glob("#{fixtures_path}/**/*.rb")

    fixture_files.each do |file|
      dir = File.dirname(file)
      name = File.basename(file, ".rb")
      puts name

      define_method("test_#{name}") do
        expected_path = File.join(dir, "#{name}.cfg.exp")
        assert(File.exist?(expected_path), "expectation file missing for #{file}")
        expected_output = File.read(expected_path)

        node = Spoom.parse_ruby(File.read(file), file: file)
        cfgs_cluster = Spoom::CFG.from_node(node)
        cfgs_cluster.compact!

        actual_output = cfgs_cluster.inspect

        if ENV["UPDATE_FIXTURES"]
          File.write(expected_path, actual_output)
          return
        end

        assert_equal(expected_output, actual_output)
      end
    end
  end
end
