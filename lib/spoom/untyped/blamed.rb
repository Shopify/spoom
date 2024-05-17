# typed: strict
# frozen_string_literal: true

module Spoom
  module Untyped
    class Blamed < T::Struct
      extend T::Sig

      const :path, String
      const :package, String
      const :owner, String
      const :name, String
      const :count, Integer

      sig { params(arg: T.untyped).returns(String) }
      def to_json(*arg)
        serialize.to_json(*arg)
      end

      class << self
        extend T::Sig

        sig { params(json: String).returns(Blamed) }
        def from_json(json)
          from_obj(JSON.parse(json))
        end

        sig { params(obj: T::Hash[String, T.untyped]).returns(Blamed) }
        def from_obj(obj)
          Blamed.new(
            path: obj.fetch("path", "<none>"),
            package: obj.fetch("package", "<none>"),
            owner: obj.fetch("owner", "<none>"),
            name: obj.fetch("name", "<none>"),
            count: obj.fetch("count", 0),
          )
        end
      end
    end
  end
end
