# typed: true
# frozen_string_literal: true

require_relative '../../snapshot'
require_relative '../command_helper'

module Spoom
  module Cli
    module Commands
      class Metrics < Thor
        include Spoom::Cli::CommandHelper

        default_task :snapshot

        desc "snapshot", "run srb tc and display metrics"
        def snapshot
          in_sorbet_project!

          snapshot = Spoom::Snapshot.snapshot
          snapshot.print
        end
      end
    end
  end
end
