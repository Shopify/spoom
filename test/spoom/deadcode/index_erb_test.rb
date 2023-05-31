# typed: true
# frozen_string_literal: true

require "test_with_project"
require "helpers/deadcode_helper"

module Spoom
  module Deadcode
    class IndexERBTest < Spoom::TestWithProject
      include Test::Helpers::DeadcodeHelper

      def test_index_erb_content
        @project.write!("foo.erb", <<~ERB)
          <div>
            <% ALIVE1.alive1.each do |x| %>
              <p><%= x %></p>
            <% end %>
          </div>
        ERB

        @project.write!("foo.rb", <<~RB)
          module ALIVE1
            def alive1; end
          end

          module DEAD1
            def dead1; end
          end
        RB

        index = deadcode_index
        assert_alive(index, "ALIVE1")
        assert_alive(index, "alive1")
        assert_dead(index, "DEAD1")
        assert_dead(index, "dead1")
      end
    end
  end
end
