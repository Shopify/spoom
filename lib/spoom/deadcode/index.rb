# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    class Index
      class Error < Spoom::Error
        #: (String message, parent: Exception) -> void
        def initialize(message, parent:)
          super(message)
          set_backtrace(parent.backtrace)
        end
      end

      # TODO: remove
      #: Model
      attr_reader :model

      #: Saturn::Graph
      attr_reader :graph

      #: Hash[String, Array[Definition]]
      attr_reader :definitions

      #: Hash[String, Array[Model::Reference]]
      attr_reader :references

      #: (Model model) -> void
      def initialize(model)
        @model = model
        @graph = Saturn::Graph.new #: Saturn::Graph
        @definitions = {} #: Hash[String, Array[Definition]]
        @references = {} #: Hash[String, Array[Model::Reference]]
        @ignored = Set.new #: Set[Model::SymbolDef]
      end

      # Indexing

      #: (Array[String] files, ?plugins: Array[Plugins::Base]) -> void
      def index_files(files, plugins: [])
        erb_files, rb_files = files.partition { |file| file.end_with?(".erb") }

        graph.index_all(rb_files)

        erb_files.each do |file|
          erb = File.read(file)
          index_erb(erb, file: file, plugins: plugins)
        end
      end

      #: (String file, ?plugins: Array[Plugins::Base]) -> void
      def index_file(file, plugins: [])
        if file.end_with?(".erb")
          erb = File.read(file)
          index_erb(erb, file: file, plugins: plugins)
        else
          rb = File.read(file)
          index_ruby(rb, file: file, plugins: plugins)
        end
      end

      #: (String erb, file: String, ?plugins: Array[Plugins::Base]) -> void
      def index_erb(erb, file:, plugins: [])
        index_ruby(Deadcode::ERB.new(erb).src, file: file, plugins: plugins)
      end

      #: (String rb, file: String, ?plugins: Array[Plugins::Base]) -> void
      def index_ruby(rb, file:, plugins: [])
        node = Spoom.parse_ruby(rb, file: file, comments: true)

        # Index definitions
        model_builder = Model::Builder.new(@model, file)
        model_builder.visit(node)

        # Index references
        refs_visitor = Model::ReferencesVisitor.new(file)
        refs_visitor.visit(node)
        refs_visitor.references.each do |ref|
          (@references[ref.name] ||= []) << ref
        end

        # Index references and sends
        indexer = Indexer.new(file, self, plugins: plugins)
        indexer.visit(node)
      rescue ParseError => e
        raise e
      rescue => e
        raise Error.new("Error while indexing #{file} (#{e.message})", parent: e)
      end

      #: (Definition definition) -> void
      def define(definition)
        (@definitions[definition.name] ||= []) << definition
      end

      #: (String name, Location location) -> void
      def reference_constant(name, location)
        (@references[name] ||= []) << Model::Reference.constant(name, location)
      end

      #: (String name, Location location) -> void
      def reference_method(name, location)
        (@references[name] ||= []) << Model::Reference.method(name, location)
      end

      #: (Model::SymbolDef symbol_def) -> void
      def ignore(symbol_def)
        @ignored << symbol_def
      end

      #: (Array[Plugins::Base] plugins) -> void
      def apply_plugins!(plugins)
        @model.symbols.each do |_full_name, symbol|
          symbol.definitions.each do |symbol_def|
            case symbol_def
            when Model::Class
              plugins.each { |plugin| plugin.internal_on_define_class(symbol_def) }
            when Model::Module
              plugins.each { |plugin| plugin.internal_on_define_module(symbol_def) }
            when Model::Constant
              plugins.each { |plugin| plugin.internal_on_define_constant(symbol_def) }
            when Model::Method
              plugins.each { |plugin| plugin.internal_on_define_method(symbol_def) }
            when Model::Attr
              plugins.each { |plugin| plugin.internal_on_define_accessor(symbol_def) }
            end
          end
        end
      end

      # Mark all definitions having a reference of the same name as `alive`
      #
      # To be called once all the files have been indexed and all the definitions and references discovered.
      #: -> void
      def finalize!
        @graph.declarations.each do |declaration|
          declaration.definitions.each do |definition|
            case definition
            when Saturn::ClassDefinition
              d = Definition.new(
                kind: Definition::Kind::Class,
                name: declaration_name(declaration.name),
                full_name: declaration.name,
                location: saturn_location_to_spoom_location(definition.location),
              )
              d.ignored! if @ignored.include?(definition)
              d.alive! if @references.key?(d.name)
              define(d)
            when Saturn::ModuleDefinition
              d = Definition.new(
                kind: Definition::Kind::Module,
                name: declaration_name(declaration.name),
                full_name: declaration.name,
                location: saturn_location_to_spoom_location(definition.location),
              )
              d.ignored! if @ignored.include?(definition)
              d.alive! if @references.key?(d.name)
              define(d)
            when Saturn::ConstantDefinition
              d = Definition.new(
                kind: Definition::Kind::Constant,
                name: declaration_name(declaration.name),
                full_name: declaration.name,
                location: saturn_location_to_spoom_location(definition.location),
              )
              d.ignored! if @ignored.include?(definition)
              d.alive! if @references.key?(d.name)
              define(d)
            when Saturn::MethodDefinition
              d = Definition.new(
                kind: Definition::Kind::Method,
                name: declaration_name(declaration.name),
                full_name: declaration.name,
                location: saturn_location_to_spoom_location(definition.location),
              )
              d.ignored! if @ignored.include?(definition)
              d.alive! if @references.key?(d.name)
              define(d)
            when Saturn::AttrAccessorDefinition
              d = if declaration.name.end_with?("=")
                Definition.new(
                  kind: Definition::Kind::AttrWriter,
                  name: declaration_name(declaration.name),
                  full_name: declaration.name,
                  location: saturn_location_to_spoom_location(definition.location),
                )
              else
                Definition.new(
                  kind: Definition::Kind::AttrReader,
                  name: declaration_name(declaration.name),
                  full_name: declaration.name,
                  location: saturn_location_to_spoom_location(definition.location),
                )
              end
              d.ignored! if @ignored.include?(definition)
              d.alive! if @references.key?(d.name)
              define(d)
            when Saturn::AttrReaderDefinition
              d = Definition.new(
                kind: Definition::Kind::AttrReader,
                name: declaration_name(declaration.name),
                full_name: declaration.name,
                location: saturn_location_to_spoom_location(definition.location),
              )
              d.ignored! if @ignored.include?(definition)
              d.alive! if @references.key?(d.name)
              define(d)
            when Saturn::AttrWriterDefinition
              d = Definition.new(
                kind: Definition::Kind::AttrWriter,
                name: declaration_name(declaration.name),
                full_name: declaration.name,
                location: saturn_location_to_spoom_location(definition.location),
              )
              d.ignored! if @ignored.include?(definition)
              d.alive! if @references.key?(d.name)
              define(d)
            end
          end
        end

        @graph.unresolved_references.each do |ref|
          case ref
          when Saturn::UnresolvedConstantReference
            reference_constant(
              declaration_name(ref.name),
              saturn_location_to_spoom_location(ref.location),
            )
          when Saturn::UnresolvedMethodReference
            reference_method(
              ref.name,
              saturn_location_to_spoom_location(ref.location),
            )
          end
        end
      end

      # TODO
      #: (String name) -> String
      def declaration_name(name)
        name.split(/(::|#)/).last #: as !nil
      end

      #: (Saturn::Location location) -> Location
      def saturn_location_to_spoom_location(location)
        Location.new(
          location.path,
          start_line: location.start_line,
          end_line: location.end_line,
          start_column: location.start_column,
          end_column: location.end_column,
        )
      end

      # Utils

      #: (String name) -> Array[Definition]
      def definitions_for_name(name)
        @definitions[name] || []
      end

      #: -> Array[Definition]
      def all_definitions
        @definitions.values.flatten
      end

      #: -> Array[Model::Reference]
      def all_references
        @references.values.flatten
      end
    end
  end
end
