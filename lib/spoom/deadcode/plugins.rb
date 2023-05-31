# typed: true
# frozen_string_literal: true

require_relative "plugins/base"
require_relative "plugins/action_mailer"
require_relative "plugins/actionpack"
require_relative "plugins/active_job"
require_relative "plugins/active_model"
require_relative "plugins/active_record"
require_relative "plugins/active_support"
require_relative "plugins/def_initialize"
require_relative "plugins/graphql"
require_relative "plugins/minitest"
require_relative "plugins/namespaces"
require_relative "plugins/rake"
require_relative "plugins/rails"
require_relative "plugins/rspec"
require_relative "plugins/ruby"
require_relative "plugins/rubocop"
require_relative "plugins/sorbet"
require_relative "plugins/thor"

module Spoom
  module Deadcode
    DEFAULT_CUSTOM_PLUGINS_PATH = ".spoom/deadcode/plugins"

    class << self
      extend T::Sig

      sig { params(context: Context).returns(T::Array[Plugins::Base]) }
      def plugins_from_gemfile_lock(context)
        plugin_classes = T.let(
          Set.new([
            # These plugins are always loaded
            Spoom::Deadcode::Plugins::DefInitialize,
            Spoom::Deadcode::Plugins::Namespaces,
            Spoom::Deadcode::Plugins::Ruby,
          ]),
          T::Set[T.class_of(Plugins::Base)],
        )

        # These plugins depends on the gems used by the project
        context.gemfile_lock_specs.keys.each do |name|
          plugin_class = case name
          when "actionmailer"
            Spoom::Deadcode::Plugins::ActionMailer
          when "actionpack"
            Spoom::Deadcode::Plugins::ActionPack
          when "activejob"
            Spoom::Deadcode::Plugins::ActiveJob
          when "activemodel"
            Spoom::Deadcode::Plugins::ActiveModel
          when "activerecord"
            Spoom::Deadcode::Plugins::ActiveRecord
          when "activesupport"
            Spoom::Deadcode::Plugins::ActiveSupport
          when "graphql"
            Spoom::Deadcode::Plugins::GraphQL
          when "minitest"
            Spoom::Deadcode::Plugins::Minitest
          when "rails"
            Spoom::Deadcode::Plugins::Rails
          when "rspec"
            Spoom::Deadcode::Plugins::RSpec
          when "rubocop"
            Spoom::Deadcode::Plugins::Rubocop
          when "sorbet", "sorbet-runtime", "sorbet-static"
            Spoom::Deadcode::Plugins::Sorbet
          when "thor"
            Spoom::Deadcode::Plugins::Thor
          end

          plugin_classes << plugin_class if plugin_class
        end

        plugin_classes.map(&:new)
      end

      sig { params(context: Context).returns(T::Array[Plugins::Base]) }
      def load_custom_plugins(context)
        context.glob("#{DEFAULT_CUSTOM_PLUGINS_PATH}/*.rb").each do |path|
          require("#{context.absolute_path}/#{path}")
        end

        ObjectSpace
          .each_object(Class)
          .select do |klass|
            next unless T.unsafe(klass) < Plugins::Base

            location = Object.const_source_location(T.unsafe(klass).to_s)&.first
            next unless location
            next unless location.start_with?("#{context.absolute_path}/#{DEFAULT_CUSTOM_PLUGINS_PATH}")

            true
          end
          .map { |klass| T.unsafe(klass).new }
      end
    end
  end
end
