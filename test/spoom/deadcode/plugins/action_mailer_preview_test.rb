# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    module Plugins
      class ActionMailerPreviewTest < TestWithProject
        include Test::Helpers::DeadcodeHelper

        def test_action_mailer_preview_ignore_direct_inheritance
          @project.write!("test/mailers/previews/my_mailer_preview.rb", <<~RB)
            class MyMailerPreview < ActionMailer::Preview
              def my_email_preview_method; end

              private

              def some_unused_private_method; end
            end

            class MyOtherMailerPreview < ::ActionMailer::Preview; end

            class MyDirectInheritanceMailerPreview < ActionMailer::Preview; end
            class MyIndirectInheritanceMailerPreview < MyDirectInheritanceMailerPreview; end

            class Foo
              def bar; end
            end
          RB

          index = index_with_plugins
          assert_ignored(index, "MyMailerPreview")
          assert_ignored(index, "MyOtherMailerPreview")
          assert_ignored(index, "my_email_preview_method")
          # refute_ignored(index, "some_unused_private_method") ideally we'd want this, but seems tricky to do
          # assert_ignored(index, "MyIndirectInheritanceMailerPreview") ideally we'd want this, but seems tricky to do
          refute_ignored(index, "Foo")
          refute_ignored(index, "bar")

          # Document current less then ideal behavior:
          assert_ignored(index, "some_unused_private_method")
          assert_ignored(index, "MyIndirectInheritanceMailerPreview")
        end

        private

        sig { returns(Index) }
        def index_with_plugins
          deadcode_index(plugin_classes: [ActionMailerPreview])
        end
      end
    end
  end
end
