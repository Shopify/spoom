# typed: strict
# frozen_string_literal: true

require "ruby_lsp/extension"

require "spoom"

module RubyLsp
  module Spoom
    class Extension < ::RubyLsp::Extension
      extend T::Sig

      sig { override.void }
      def activate
        @config = read_config_spoom_file
      end

      sig { override.returns(String) }
      def name
        "Spoom server"
      end

      def factory()
        OnSaveListener.new(config, )
      end

      class OnSaveListener < ::RubyLsp::Listener
        extend T::Sig

        ResponseType = type_member { { fixed: T.untyped } }

        def initialize(e, mq)
          @e = mq
        end

        sig { returns(Thread::Queue) }
        def message_queue
          instance_variable_get(:@message_queue)
        end

        sig { override.returns(ResponseType) }
        def response
          candidates_by_files = run_deadcode_analysis.group_by do |candidate|
            candidate.location.file
          end

          candidates_by_files.each do |file, candidates|
            message_queue << Notification.new(
              message: "textDocument/publishDiagnostics",
              params: RubyLsp::Interface::PublishDiagnosticsParams.new(
                uri: "file://#{file}",
                diagnostics: candidates.map do |candidate|
                  RubyLsp::Interface::Diagnostic.new(
                    range: RubyLsp::Interface::Range.new(
                      start: RubyLsp::Interface::Position.new(
                        line: candidate.location.start_line - 1,
                        character: candidate.location.start_column,
                      ),
                      end: RubyLsp::Interface::Position.new(
                        line: candidate.location.end_line - 1,
                        character: candidate.location.end_column,
                      ),
                    ),
                    severity: RubyLsp::Constant::DiagnosticSeverity::WARNING,
                    source: "spoom deadcode",
                    message: "Potentially unused #{candidate.kind.serialize} #{candidate.full_name}",
                  )
                end,
              ),
            )
          end
        end

        private

        sig { returns(T::Array[::Spoom::Deadcode::Definition]) }
        def run_deadcode_analysis
          context = ::Spoom::Context.new(".")

          $stderr.puts "Spoom: Collecting files..."

          collector = ::Spoom::FileCollector.new(
            allow_extensions: [".rb"],
            allow_mime_types: ["text/x-ruby", "text/x-ruby-script"],
            exclude_patterns: ["vendor/**", "sorbet/**"].map { |p| File.join(context.absolute_path, p) },
          )

          collector.visit_paths([context.absolute_path])
          files = collector.files.sort

          $stderr.puts "Spoom: Collected #{files.size} files for analysis"

          plugins = ::Spoom::Deadcode.plugins_from_gemfile_lock(context)
          $stderr.puts "Spoom: Loaded #{plugins.size} plugins"

          $stderr.puts "Spoom: Indexing #{files.size} files..."
          index = ::Spoom::Deadcode::Index.new
          files.each_with_index do |file, i|
            content = File.read(file)
            if file.end_with?(".erb")
              ::Spoom::Deadcode.index_erb(index, content, file: file, plugins: plugins)
            else
              ::Spoom::Deadcode.index_ruby(index, content, file: file, plugins: plugins)
            end
          rescue ::Spoom::Deadcode::ParserError => e
            $stderr.puts "Spoom: Error parsing #{file}: #{e.message}"
          end

          definitions_count = index.definitions.size
          references_count = index.references.size
          $stderr.puts "Spoom: Analyzing #{definitions_count} definitions against #{references_count} references..."

          index.finalize!
          dead = index.definitions.values.flatten.select(&:dead?)

          if dead.empty?
            $stderr.puts "Spoom: No dead code found!"
          else
            $stderr.puts "Spoom: Found #{dead.size} dead candidates"
          end

          dead
        end
      end
    end
  end
end
