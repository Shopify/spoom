# typed: strict
# frozen_string_literal: true

module Spoom
  module Deadcode
    module Plugins
      class Protobuf < Base
        # @override
        #: (Model::Module definition) -> void
        def on_define_module(definition)
          file = definition.location.file
          @index.ignore(definition) if file.match?(%r{lib/protobuf/.*})
        end

        # @override
        #: (Model::Class definition) -> void
        def on_define_class(definition)
          file = definition.location.file
          @index.ignore(definition) if file.match?(%r{lib/protobuf/.*})
        end

        # @override
        #: (Model::Constant definition) -> void
        def on_define_constant(definition)
          file = definition.location.file
          @index.ignore(definition) if file.match?(%r{lib/protobuf/.*})
        end

        # @override
        #: (Model::Method definition) -> void
        def on_define_method(definition)
          file = definition.location.file
          @index.ignore(definition) if file.match?(%r{lib/protobuf/.*})
        end
      end
    end
  end
end
