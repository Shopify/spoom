# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    class PluginsTest < Spoom::TestWithProject
      def test_deadcode_plugins_with_no_gemfile_lock
        plugins = plugins_classes_for_gemfile(<<~GEMFILE)
          source "https://rubygems.org"
        GEMFILE

        assert_equal(
          [
            Spoom::Deadcode::Plugins::Namespaces,
            Spoom::Deadcode::Plugins::Ruby,
          ],
          plugins,
        )
      end

      def test_deadcode_plugins_with_rails
        plugins = plugins_classes_for_gemfile(<<~GEMFILE)
          source "https://rubygems.org"

          gem "rails"
        GEMFILE

        assert_equal(
          [
            Spoom::Deadcode::Plugins::Namespaces,
            Spoom::Deadcode::Plugins::Ruby,
            Spoom::Deadcode::Plugins::ActionMailer,
            Spoom::Deadcode::Plugins::ActionPack,
            Spoom::Deadcode::Plugins::ActiveJob,
            Spoom::Deadcode::Plugins::ActiveModel,
            Spoom::Deadcode::Plugins::ActiveRecord,
            Spoom::Deadcode::Plugins::ActiveSupport,
            Spoom::Deadcode::Plugins::Minitest,
            Spoom::Deadcode::Plugins::Rails,
            Spoom::Deadcode::Plugins::Rake,
            Spoom::Deadcode::Plugins::Thor,
          ],
          plugins,
        )
      end

      def test_deadcode_plugins_with_sorbet
        plugins = plugins_classes_for_gemfile(<<~GEMFILE)
          source "https://rubygems.org"

          #{Spoom::BundlerHelper.gem_requirement_from_real_bundle("sorbet")}
          #{Spoom::BundlerHelper.gem_requirement_from_real_bundle("sorbet-runtime")}
        GEMFILE

        assert_equal(
          [
            Spoom::Deadcode::Plugins::Namespaces,
            Spoom::Deadcode::Plugins::Ruby,
            Spoom::Deadcode::Plugins::Sorbet,
          ],
          plugins,
        )
      end

      def test_deadcode_load_custom_plugins
        context = Context.mktmp!

        context.write!("#{Spoom::Deadcode::DEFAULT_CUSTOM_PLUGINS_PATH}/plugin1.rb", <<~RB)
          class Plugin1 < Spoom::Deadcode::Plugins::Base
            ignore_classes_named("Foo", "Bar")
          end
        RB

        context.write!("#{Spoom::Deadcode::DEFAULT_CUSTOM_PLUGINS_PATH}/plugin2.rb", <<~RB)
          class Plugin2 < Spoom::Deadcode::Plugins::Base
            ignore_classes_named("Foo", "Bar")
          end
        RB

        context.write!("#{Spoom::Deadcode::DEFAULT_CUSTOM_PLUGINS_PATH}/not_a_plugin.rb", <<~RB)
          class NotAPlugin
          end
        RB

        plugins = Spoom::Deadcode.load_custom_plugins(context)

        assert_equal(["Plugin1", "Plugin2"], plugins.map(&:name).sort)

        context.destroy!
      end

      def test_deadcode_load_custom_plugins_ignore_anonymous_classes
        # Create an anonymous plugin class that shouldn't be loaded
        Class.new(Spoom::Deadcode::Plugins::Base)

        context = Context.mktmp!
        plugins = Spoom::Deadcode.load_custom_plugins(context)

        assert_empty(plugins)

        context.destroy!
      end

      private

      #: (String gemfile_string) -> Array[singleton(Plugins::Base)]
      def plugins_classes_for_gemfile(gemfile_string)
        context = Context.mktmp!
        context.write_gemfile!(gemfile_string)
        result = context.bundle("lock")

        raise "Can't `bundle install`: #{result.err}" unless result.status

        plugin_classes = Deadcode.plugins_from_gemfile_lock(context)
        context.destroy!
        plugin_classes.to_a
      end
    end
  end
end
