# typed: strict
# frozen_string_literal: true

require_relative "../untyped"

module Spoom
  module Cli
    class Untyped < Thor
      extend T::Sig
      include Helper

      default_task :untyped

      desc "untyped", "Find cause of untyped calls"
      option :sort,
        type: :string,
        default: "count",
        enum: ["count", "owner", "path"],
        desc: "Sort the output by count, owner, or path"
      option :sorbet,
        type: :string,
        desc: "Path to custom Sorbet bin"
      sig { params(paths: String).void }
      def untyped(*paths)
        context = self.context

        blamed = Spoom::Untyped.blame(context, sorbet_bin: options[:sorbet])
        puts(blamed)
      end
    end
  end
end
