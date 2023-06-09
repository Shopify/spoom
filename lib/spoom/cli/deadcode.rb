# typed: true
# frozen_string_literal: true

require_relative "../deadcode"

module Spoom
  module Cli
    class Deadcode < Thor
      extend T::Sig
      include Helper

      default_task :deadcode

      desc "deadcode PATH...", "Analyze PATHS to find dead code"
      option :allowed_extensions,
        type: :array,
        default: [".rb", ".erb", ".gemspec"],
        aliases: :e,
        desc: "Allowed extensions"
      option :allowed_mime_types,
        type: :array,
        default: ["text/x-ruby", "text/x-ruby-script"],
        aliases: :m,
        desc: "Allowed mime types"
      option :exclude,
        type: :array,
        default: ["vendor/", "sorbet/"],
        aliases: :x,
        desc: "Exclude paths"
      option :accessors,
        type: :boolean,
        default: true,
        desc: "Check for unused attribute accessors"
      option :classes,
        type: :boolean,
        default: true,
        desc: "Check for unused classes"
      option :constants,
        type: :boolean,
        default: true,
        desc: "Check for unused constants"
      option :methods,
        type: :boolean,
        default: true,
        desc: "Check for unused methods"
      option :modules,
        type: :boolean,
        default: true,
        desc: "Check for unused modules"
      option :show_files,
        type: :boolean,
        default: false,
        desc: "Show the files that will be analyzed"
      option :show_plugins,
        type: :boolean,
        default: false,
        desc: "Show the loaded plugins"
      option :show_defs,
        type: :boolean,
        default: false,
        desc: "Show the indexed definitions"
      option :show_refs,
        type: :boolean,
        default: false,
        desc: "Show the indexed references"
      option :sort,
        type: :string,
        default: "name",
        enum: ["name", "location"],
        desc: "Sort the output by name or location"
      option :json,
        type: :boolean,
        default: false,
        desc: "Output the result as JSON"
      sig { params(paths: String).void }
      def deadcode(*paths)
        context = self.context

        paths << exec_path if paths.empty?

        $stderr.puts "Collecting files..."
        collector = FileCollector.new(
          allow_extensions: options[:allowed_extensions],
          allow_mime_types: options[:allowed_mime_types],
          exclude_patterns: options[:exclude].map { |p| Pathname.new(File.join(exec_path, p, "**")).cleanpath.to_s },
        )
        collector.visit_paths(paths)
        files = collector.files.sort

        if options[:show_files]
          $stderr.puts "\nCollected #{blue(files.size.to_s)} files for analysis:"
          files.each do |file|
            $stderr.puts "  #{gray(file)}"
          end
          $stderr.puts
        end

        plugins = Spoom::Deadcode.plugins_from_gemfile_lock(context)
        if options[:show_plugins]
          $stderr.puts "\nLoaded #{blue(plugins.size.to_s)} plugins:"
          plugins.each do |plugin|
            $stderr.puts "  #{gray(plugin.class.to_s)}"
          end
          $stderr.puts
        end

        $stderr.puts "Indexing #{blue(files.size.to_s)} files..."
        index = Spoom::Deadcode::Index.new
        files.each_with_index do |file, i|
          $stderr.print("#{i + 1}/#{files.size}\r")

          content = File.read(file)
          if file.end_with?(".erb")
            Spoom::Deadcode.index_erb(index, content, file: file, plugins: plugins)
          else
            Spoom::Deadcode.index_ruby(index, content, file: file, plugins: plugins)
          end
        rescue Spoom::Deadcode::ParserError => e
          say_error("Error parsing #{file}: #{e.message}")
          next
        end

        unless options[:json]
          if options[:show_defs]
            $stderr.puts "Definitions:"
            index.definitions.each do |name, definitions|
              $stderr.puts "  #{blue(name)}"
              definitions.each do |definition|
                $stderr.puts "    #{yellow(definition.kind.serialize)} #{gray(definition.location.to_s)}"
              end
            end
          end

          if options[:show_refs]
            $stderr.puts "References:"
            index.references.values.flatten.sort_by(&:name).each do |references|
              name = references.name
              kind = references.kind.serialize
              loc = references.location.to_s
              $stderr.puts "  #{blue(name)} #{yellow(kind)} #{gray(loc)}"
            end
          end
        end

        definitions_count = index.definitions.size.to_s
        references_count = index.references.size.to_s
        $stderr.puts "Analyzing #{blue(definitions_count)} definitions against #{blue(references_count)} references..."

        index.finalize!
        dead = index.definitions.values.flatten.select(&:dead?)

        if options[:sort] == "name"
          dead.sort_by!(&:name)
        else
          dead.sort_by!(&:location)
        end

        if options[:json]
          puts JSON.pretty_generate(dead)
        elsif dead.empty?
          $stderr.puts "\n#{green("No dead code found!")}"
        else
          $stderr.puts "\nCandidates:"
          dead = dead.reject(&:constant?) unless options[:constants]
          dead = dead.reject(&:class?) unless options[:classes]
          dead = dead.reject(&:module?) unless options[:modules]
          dead = dead.reject(&:method?) unless options[:methods]

          unless options[:accessors]
            dead = dead.reject(&:attr_reader?)
            dead = dead.reject(&:attr_writer?)
          end

          dead.each do |definition|
            $stderr.puts "  #{red(definition.full_name)} #{gray(definition.location.to_s)}"
          end
          $stderr.puts "\n"
          $stderr.puts red("  Found #{dead.size} dead candidates")
        end

        # TODO: handle aliases
        # TODO: auto-delete deadcode

        # TODO: allow manual allowlist
        # TODO: load plugins from .spoom + tests

        # TODO: delegate, def_delegators (forwardable)
        # TODO: erb could be a plugin: on_file?
        # TODO: find overrides from RBIs?
        # TODO: find unused instance variables?

        # TODO: better DSLs routes?
        # TODO: we can be smarter about the initialize
        # TODO: we can be smarter about the methods we match: use the receiver to filter out methods actually called
        # TODO: we can be smarter about the filters to base on superclasses using Sorbet
        # TODO: we can be smarter about class << self?

        # TODO: tests: cli

        # TODO: confidence score?
        # TODO: speed up file collection?
        # TODO: run without sorbet?
      end

      desc "remove KIND LOCATION", "Remove dead code at LOCATION"
      def remove(kind, location_string)
        location = Spoom::Deadcode::Location.from_string(location_string)
        context = self.context
        remover = Spoom::Deadcode::Remover.new(context)

        kind_enum = Spoom::Deadcode::Definition::Kind.deserialize(kind)
        remover.remove_location(kind_enum, location)

        # TODO: give some output
      rescue KeyError
        say_error("Invalid kind: #{kind}, expected one of #{Spoom::Deadcode::Definition::Kind.values}")
        exit(1)
      rescue Spoom::Deadcode::Location::LocationError => e
        say_error(e.message)
        exit(1)
      end
    end
  end
end
