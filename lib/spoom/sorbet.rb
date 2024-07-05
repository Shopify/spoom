# typed: strict
# frozen_string_literal: true

require "spoom/sorbet/config"
require "spoom/sorbet/errors"
require "spoom/sorbet/lsp"
require "spoom/sorbet/metrics"
require "spoom/sorbet/sigils"

require "open3"

module Spoom
  module Sorbet
    class Error < Spoom::Error
      extend T::Sig

      class Killed < Error; end
      class Segfault < Error; end

      sig { returns(ExecResult) }
      attr_reader :result

      sig do
        params(
          message: String,
          result: ExecResult,
        ).void
      end
      def initialize(message, result)
        super(message)

        @result = result
      end
    end

    CONFIG_PATH = "sorbet/config"
    GEM_PATH = T.let(Gem::Specification.find_by_name("sorbet-static").full_gem_path, String)
    GEM_VERSION = T.let(Gem::Specification.find_by_name("sorbet-static-and-runtime").version.to_s, String)
    BIN_PATH = T.let((Pathname.new(GEM_PATH) / "libexec" / "sorbet").to_s, String)

    KILLED_CODE = 137
    SEGFAULT_CODE = 139
  end
end
