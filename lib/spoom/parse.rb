# typed: strict
# frozen_string_literal: true

module Spoom
  class ParseError < Error; end

  class << self
    extend T::Sig

    sig { params(file: String).returns(Prism::Node) }
    def parse_file(file)
      ruby = File.read(file)
      parse_ruby(ruby, file: file)
    end

    sig { params(ruby: String, file: String).returns(Prism::Node) }
    def parse_ruby(ruby, file:)
      result = Prism.parse(ruby)
      unless result.success?
        message = result.errors.map do |e|
          "#{e.message} (at #{e.location.start_line}:#{e.location.start_column})."
        end.join(" ")

        raise ParseError, "Error while parsing #{file}: #{message}"
      end

      result.value
    end
  end
end
