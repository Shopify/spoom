# typed: strict
# frozen_string_literal: true

require_relative "file_tree"
require_relative "snapshot"
require_relative "coverage/d3"

require "date"
require "erb"

module Spoom
  module Coverage
    extend T::Sig

    sig { params(snapshots: T::Array[Snapshot], path: String).returns(Report) }
    def self.report(snapshots, path: ".")
      intro = T.must(Git.sorbet_intro_commit(path: path))
      Report.new(
        title: File.basename(File.expand_path(path)),
        sorbet_intro_commit: intro,
        sorbet_intro_date: T.must(Git.commit_time(intro, path: path)),
        sigils_tree: sigils_tree(path: path),
        snapshots: snapshots
      )
    end

    sig { params(path: String).returns(FileTree) }
    def self.sigils_tree(path: ".")
      config_file = "#{path}/#{Spoom::Config::SORBET_CONFIG}"
      return FileTree.new unless File.exist?(config_file)
      config = Sorbet::Config.parse_file(config_file)
      files = Sorbet.srb_files(config, path: path)
      files.select! { |file| file =~ /\.rb$/ }
      files.reject! { |file| file =~ %r{/test/} }
      FileTree.new(files)
    end

    class Report < T::Struct
      extend T::Sig

      prop :title, String, default: "Typing Coverage"
      prop :sorbet_intro_commit, String
      prop :sorbet_intro_date, Time
      prop :sigils_tree, FileTree
      prop :snapshots, T::Array[Snapshot]

      sig { returns(Snapshot) }
      def last
        T.must(snapshots.last)
      end

      sig { returns(String) }
      def html
        ERB.new(erb).result(get_binding)
      end

      sig { returns(Binding) }
      def get_binding # rubocop:disable Naming/AccessorMethodName
        binding
      end

      sig { returns(T::Hash[String, D3::Base]) }
      def cards
        {
          "Strictness Map": D3::MapSigils.new("map_sigils", sigils_tree),
          "Sigils Timeline": D3::TimelineSigils.new("timeline_sigils", snapshots),
          "Calls Timeline": D3::TimelineCalls.new("timeline_calls", snapshots),
          "Signatures Timeline": D3::TimelineSigs.new("timeline_sigs", snapshots),
          "Sorbet Version": D3::TimelineVersions.new("timeline_versions", snapshots),
          "Sorbet Typechecking Time": D3::TimelineRuntimes.new("timeline_runtimes", snapshots),
        }
      end

      sig { returns(String) }
      def erb
        <<~ERB
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="utf-8" />
            <meta http-equiv="x-ua-compatible" content="ie=edge" />
            <meta name="viewport" content="width=device-width, initial-scale=1" />

            <title>#{title}</title>
            <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/css/bootstrap.min.css">

            <style>
              #{D3.header_style}
            </style>
          </head>
          <body>
            <script src="https://code.jquery.com/jquery-3.5.1.slim.min.js"></script>
            <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.0/js/bootstrap.min.js"></script>
            <script src="https://d3js.org/d3.v4.min.js"></script>

            <script>
              #{D3.header_script}
            </script>

            <div class="px-5 py-4 container-fluid">
              <div class="row justify-content-center">
                <div class="col-xs-12 col-md-12 col-lg-9 col-xl-8">
                  <h1 class="display-3">
                    #{title}
                    <span class="badge badge-pill badge-dark" style="font-size: 20%;">#{last.commit_sha}</span>
                  </h1>
                  <br>
                  <div class="card">
                    <h5 class="card-header">Snapshot</h5>
                    <div class="card-body">
                      <div class="container-fluid">
                        <div class="row justify-content-md-center">
                          <div class="col-12 col-sm-4 col-xl-3">
                            #{D3::PieSigils.new('pie_sigils', 'Sigils', last).html}
                          </div>
                          <div class="d-none d-xl-block col-xl-1"></div>
                          <div class="col-12 col-sm-4 col-xl-3">
                            #{D3::PieCalls.new('pie_calls', 'Calls', last).html}
                          </div>
                          <div class="d-none d-xl-block col-xl-1"></div>
                          <div class="col-12 col-sm-4 col-xl-3">
                            #{D3::PieSigs.new('pie_sigs', 'Sigs', last).html}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                  <br>
                  <% cards.each do |title, d3| %>
                    <div class="card">
                      <h5 class="card-header"><%= title %></h5>
                      <div class="card-body">
                        <%= d3.html %>
                      </div>
                    </div>
                    <br>
                  <% end %>
                 </div>
                </div>
                <div class="text-center">
                  <p>
                    Typchecked by Sorbet since <b>#{sorbet_intro_date.strftime('%F')}</b>
                    (commit <b>#{sorbet_intro_commit}</b>).
                  </p>
                  <p class="text-muted" style="margin-top: 30px;">
                    Generated by <a href="https://github.com/Shopify/spoom">spoom</a>
                    on #{Time.now.utc}.
                  </p>
                </div>
              </div>
            </div>
          </body>
          </html>
        ERB
      end
    end
  end
end
