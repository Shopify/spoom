# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    module UntypedParser
      class << self
        extend T::Sig

        sig { params(path: String).returns(T::Array[T::Hash[String, T.any(String, Integer)]]) }
        def parse_file(path)
          parse_string(File.read(path))
        end

        sig { params(string: String).returns(T::Array[T::Hash[String, T.any(String, Integer)]]) }
        def parse_string(string)
          JSON.parse(string)
        rescue JSON::ParserError
          # This can occur when nothing it output to the file.
          # The cause of this will likely be that the sorbet executable wasn't compiled with
          # the `untyped-blame` flag.
          []
        end
      end
    end
  end
end
