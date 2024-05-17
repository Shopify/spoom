# typed: strict
# frozen_string_literal: true

require_relative "untyped/blamed"

module Spoom
  module Untyped
    class << self
      extend T::Sig

      sig do
        params(
          context: Context,
          sorbet_bin: T.nilable(String),
        ).returns(T::Array[Blamed])
      end
      def blame(context, sorbet_bin: nil)
        config = context.sorbet_config
        config.allowed_extensions.push(".rb", ".rbi") if config.allowed_extensions.empty?

        flags = [
          "--no-config",
          "--no-error-sections",
          "--no-error-count",
          "--isolate-error-code=0",
          config.options_string,
        ]

        untyped = context.srb_untyped(*flags, sorbet_bin: sorbet_bin)

        untyped.map do |blamed|
          Blamed.new(
            path: T.cast(blamed["path"], String),
            package: T.cast(blamed["package"], String),
            owner: T.cast(blamed["owner"], String),
            name: T.cast(blamed["name"], String),
            count: T.cast(blamed["count"], Integer),
          )
        end
      end
    end
  end
end
