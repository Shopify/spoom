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
      test_name = "test_#{name}"

      define_method(test_name) do
        T.bind(self, Minitest::Test)

        node = Spoom.parse_ruby(File.read(file), file: file)
        cfgs_cluster = Spoom::CFG.from_node(node)
        cfgs_cluster.compact!

        actual_output = cfgs_cluster.inspect

        if ENV["SHOW"]
          puts file
          puts
          puts actual_output
          cfgs_cluster.show_dot
        end

        expected_path = File.join(dir, "#{name}.cfg")

        if ENV["UPDATE"]
          File.write(expected_path, actual_output)
        else
          assert(File.exist?(expected_path), "expectation file missing for #{file}")
          expected_output = File.read(expected_path)

          unless expected_output == actual_output
            raise <<~MSG
              CFG expectation failed

              #{file}

              #{diff(expected_output, actual_output)}

              #{expected_path}
            MSG
          end
        end
      end
    end
  end
end
