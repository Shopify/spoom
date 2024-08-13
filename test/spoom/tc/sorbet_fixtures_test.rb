# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class SorbetTest < Minitest::Test
    fixtures_path = File.expand_path("fixtures", __dir__)
    fixture_files = Dir.glob("#{fixtures_path}/**/*.rb")

    fixture_files.each do |file|
      name = File.basename(file, ".rb")
      puts name

      define_method("test_#{name}") do
        node = Spoom.parse_ruby(File.read(file), file: file)

        model = Spoom::Model.new
        model_builder = Spoom::Model::Builder.new(model, file)
        model_builder.visit(node)
        model.finalize!

        resolver = Spoom::Resolver.new(model, file)
        resolver.visit(node)
      end
    end
  end
end
