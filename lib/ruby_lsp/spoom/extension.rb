# typed: ignore
# frozen_string_literal: true

require "ruby_lsp/extension"

require "spoom"

module RubyLsp
  module Spoom
    class Extension < ::RubyLsp::Extension
      extend T::Sig

      module ModelUtils
        extend T::Sig

        sig { returns(::Spoom::Model) }
        def build_model
          files = collect_files

          models = Parallel.map(files, in_processes: 10) do |file|
            ::Spoom::Model.from_file(file)
          end

          model = ::Spoom::Model.merge(models)
          model.resolve_ancestors!
          model
        end

        sig { returns(T::Array[String]) }
        def collect_files
          collector = ::Spoom::FileCollector.new(
            exclude_patterns: ["vendor/**/*"],
            allow_extensions: [".rb"],
          )
          collector.visit_path(".")
          collector.files
        end

        sig { params(ref: ::Spoom::Model::Scope).returns(RubyLsp::Interface::TypeHierarchyItem) }
        def ref_hierarchy_item(ref)
          RubyLsp::Interface::TypeHierarchyItem.new(
            name: ref.full_name,
            kind: ref_kind(ref),
            uri: ref_uri(ref),
            range: ref_range(ref),
            selection_range: ref_selection_range(ref),
          )
        end

        sig { params(ref: ::Spoom::Model::Scope).returns(Integer) }
        def ref_kind(ref)
          case ref
          when ::Spoom::Model::Class
            RubyLsp::Constant::SymbolKind::CLASS
          else
            RubyLsp::Constant::SymbolKind::MODULE
          end
        end

        sig { params(ref: ::Spoom::Model::Scope).returns(String) }
        def ref_uri(ref)
          path = File.absolute_path(ref.location.file)
          "file://#{path}"
        end

        sig { params(ref: ::Spoom::Model::Scope).returns(RubyLsp::Interface::Range) }
        def ref_range(ref)
          RubyLsp::Interface::Range.new(
            start: RubyLsp::Interface::Position.new(
              line: ref.location.start_line - 1,
              character: ref.location.start_column,
            ),
            end: RubyLsp::Interface::Position.new(
              line: ref.location.end_line,
              character: ref.location.end_column,
            ),
          )
        end

        sig { params(ref: ::Spoom::Model::Scope).returns(RubyLsp::Interface::Range) }
        def ref_selection_range(ref)
          # TODO
          RubyLsp::Interface::Range.new(
            start: RubyLsp::Interface::Position.new(
              line: ref.location.start_line - 1,
              character: ref.location.start_column,
            ),
            end: RubyLsp::Interface::Position.new(
              line: ref.location.start_line - 1,
              character: ref.location.start_column,
            ),
          )
        end
      end

      class << self
        extend T::Sig
        include ModelUtils

        sig { returns(::Spoom::Model) }
        def model
          @model ||= T.let(build_model, T.nilable(::Spoom::Model))
        end
      end

      sig { override.void }
      def activate
        # Preload the model
        self.class.model
      end

      sig { override.returns(String) }
      def name
        "Spoom server"
      end

      class TypeHierarchySupertypes < ::RubyLsp::Listener
        extend T::Sig

        include ModelUtils

        ResponseType = type_member { { fixed: T.untyped } }

        ::RubyLsp::Requests::TypeHierarchySupertypes.add_listener(self)

        sig do
          params(
            emitter: RubyLsp::EventEmitter,
            message_queue: Thread::Queue,
            item: ::RubyLsp::Interface::TypeHierarchyItem,
          ).void
        end
        def initialize(emitter, message_queue, item)
          super(emitter, message_queue)

          @item = item
        end

        sig { override.returns(ResponseType) }
        def response
          model = ::RubyLsp::Spoom::Extension.model
          model.parents_of(@item.name).flat_map do |ref|
            next unless ref.is_a?(::Spoom::Model::Scope)

            ref_hierarchy_item(ref)
          end
        rescue ::Spoom::Model::SymbolNotFound
          nil
        end
      end

      class TypeHierarchySubtypes < ::RubyLsp::Listener
        extend T::Sig

        include ModelUtils

        ResponseType = type_member { { fixed: T.untyped } }

        ::RubyLsp::Requests::TypeHierarchySubtypes.add_listener(self)

        sig do
          params(
            emitter: RubyLsp::EventEmitter,
            message_queue: Thread::Queue,
            item: ::RubyLsp::Interface::TypeHierarchyItem,
          ).void
        end
        def initialize(emitter, message_queue, item)
          super(emitter, message_queue)

          @item = item
        end

        sig { override.returns(ResponseType) }
        def response
          model = ::RubyLsp::Spoom::Extension.model
          model.children_of(@item.name).flat_map do |ref|
            next unless ref.is_a?(::Spoom::Model::Scope)

            ref_hierarchy_item(ref)
          end
        rescue ::Spoom::Model::SymbolNotFound
          nil
        end
      end
    end
  end
end
