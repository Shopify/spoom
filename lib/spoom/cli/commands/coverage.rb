# typed: true
# frozen_string_literal: true

require_relative '../../snapshot'
require_relative '../../timeline'
require_relative '../command_helper'

module Spoom
  module Cli
    module Commands
      class Coverage < Thor
        include Spoom::Cli::CommandHelper

        default_task :snapshot

        desc "snapshot", "run srb tc and display metrics"
        def snapshot
          in_sorbet_project!

          snapshot = Spoom::Coverage.snapshot(path: exec_path)
          snapshot.print
        end

        desc "timeline", "replay a project and collect metrics"
        option :from, type: :string
        option :to, type: :string, default: Time.now.strftime("%F")
        option :save_dir, type: :string
        def timeline
          in_sorbet_project!
          path = exec_path

          sha_before = Spoom::Git.last_commit(path: path)
          unless sha_before
            say_error("Not in a git repository")
            $stderr.puts "\nSpoom needs to checkout into your previous commits to build the timeline."
            exit(1)
          end

          unless Spoom::Git.workdir_clean?(path: path)
            say_error("Uncommited changes")
            $stderr.puts "\nSpoom needs to checkout into your previous commits to build the timeline."
            $stderr.puts "\nPlease git commit or git stash your changes then try again."
            exit(1)
          end

          save_dir = options[:save_dir]
          FileUtils.mkdir_p(save_dir) if save_dir

          from = parse_date(options[:from], "--from")
          to = parse_date(options[:to], "--to")

          unless from
            intro_sha = Spoom::Git.sorbet_intro_commit(path: path)
            intro_sha = T.must(intro_sha) # we know it's in there since in_sorbet_project!
            from = Spoom::Git.commit_date(intro_sha, path: path)
          end

          timeline = Spoom::Timeline.new(from, to, path: path)
          ticks = timeline.ticks

          if ticks.empty?
            say_error("No commits to replay, try different --from and --to options")
            exit(1)
          end

          ticks.each_with_index do |sha, i|
            date = Spoom::Git.commit_date(sha, path: path)
            puts "Analyzing commit #{sha} - #{date&.strftime('%F')} (#{i + 1} / #{ticks.size})"

            Spoom::Git.checkout(sha, path: path)
            snapshot = Spoom::Coverage.snapshot(path: path)
            snapshot.commit_sha = sha
            snapshot.commit_timestamp = date&.strftime('%s').to_i
            snapshot.print(indent_level: 2)
            puts "\n"

            next unless save_dir
            file = "#{save_dir}/#{sha}.json"
            puts "  Snapshot data saved under #{file}\n\n"
            File.write(file, snapshot.serialize.to_json)
          end
          Spoom::Git.checkout(sha_before, path: path)
        end

        no_commands do
          def parse_date(string, option)
            return nil unless string
            Time.parse(string)
          rescue ArgumentError
            say_error("Invalid date `#{string}` for option #{option} (expected format YYYY-MM-DD)")
            exit(1)
          end
        end
      end
    end
  end
end
