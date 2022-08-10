# typed: strict
# frozen_string_literal: true

module Spoom
  module Docs
    class Index
      extend T::Sig

      sig { params(model: Model).void }
      def initialize(model)
        @model = model
      end

      sig { returns(String) }
      def to_html
        html = String.new
        html << "<table>"
        html << "<tr>"
        html << "<td style=\"vertical-align: top\">"
        html << "<h3>Files</h3>"
        @model.files.sort.each do |file|
          html << "<a href='../#{link_for_file(file)}'>#{file}</a><br>"
        end
        html << "</td>"
        html << "<td style=\"vertical-align: top\">"
        html << "<h3>Scopes</h3>"
        @model.scopes.sort_by(&:name).each do |scope|
          html << "<a href='../#{link_for_scope(scope)}'>#{scope.name}</a><br>"
        end
        html << "</td>"
        html << "<td style=\"vertical-align: top\">"
        html << "<h3>Props</h3>"
        @model.props.sort_by(&:name).each do |prop|
          html << "<a href='../#{link_for_prop(prop)}'>#{prop.name}</a><br>"
        end
        html << "</td>"
        html << "</tr>"
        html
      end

      private

      sig { params(file: String).returns(String) }
      def link_for_file(file)
        "docs/files/#{file}.html"
      end

      sig { params(scope: Model::Scope).returns(String) }
      def link_for_scope(scope)
        "docs/scopes/#{scope.name}.html"
      end

      sig { params(prop: Model::Prop).returns(String) }
      def link_for_prop(prop)
        "docs/props/#{prop.name}.html"
      end
    end
  end
end
