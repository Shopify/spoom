# typed: true
# frozen_string_literal: true

require "spoom/sorbet/config"
require "spoom/sorbet/errors"
require "spoom/sorbet/lsp"

require "open3"

module Spoom
  module Sorbet
    extend T::Sig

    # List all files typechecked by Sorbet from its `config`
    sig { params(config: Config, path: String).returns(T::Array[String]) }
    def self.srb_files(config, path: '.')
      regs = config.ignore.map { |string| Regexp.new(Regexp.escape(string)) }
      exts = config.allowed_extensions.empty? ? ['.rb', '.rbi'] : config.allowed_extensions
      Dir.glob((Pathname.new(path) / "**/*{#{exts.join(',')}}").to_s).reject do |f|
        regs.any? { |re| re.match?(f) }
      end.sort
    end
  end
end
