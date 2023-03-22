# typed: strict
# frozen_string_literal: true

require_relative "base"

module Spoom
  module Coverage
    module D3
      class CircleMap < Base
        class << self
          extend T::Sig

          sig { returns(String) }
          def header_style
            <<~CSS
              .node {
                cursor: pointer;
              }

              .node:hover {
                stroke: #333;
                stroke-width: 1px;
              }

              .label.dir {
                fill: #333;
              }

              .label.file {
                font: 12px Arial, sans-serif;
              }

              .node.root, .node.file {
                pointer-events: none;
              }
            CSS
          end

          sig { returns(String) }
          def header_script
            <<~JS
              function treeHeight(root, height = 0) {
                height += 1;
                if (root.children && root.children.length > 0)
                  return Math.max(...root.children.map(child => treeHeight(child, height)));
                else
                  return height;
              }

              function tooltipMap(d) {
                moveTooltip(d)
                  .html("<b>" + d.data.name + "</b>")
              }
            JS
          end
        end

        sig { override.returns(String) }
        def script
          <<~JS
            var root = {children: #{@data.to_json}}
            var dataHeight = treeHeight(root)

            var opacity = d3.scaleLinear()
                .domain([0, dataHeight])
                .range([0, 0.2])

            root = d3.hierarchy(root)
                .sum((d) => d.children ? d.children.length : 1)
                .sort((a, b) => b.value - a.value);

            var dirColor = d3.scaleLinear()
              .domain([1, 0])
              .range([strictnessColor("true"), strictnessColor("false")])
              .interpolate(d3.interpolateRgb);

            function redraw() {
              var diameter = document.getElementById("#{id}").clientWidth - 20;
              d3.select("##{id}").selectAll("*").remove()

              var svg_#{id} = d3.select("##{id}")
                .attr("width", diameter)
                .attr("height", diameter)
                .append("g")
                  .attr("transform", "translate(" + diameter / 2 + "," + diameter / 2 + ")");

              var pack = d3.pack()
                  .size([diameter, diameter])
                  .padding(2);

              var focus = root,
                  nodes = pack(root).descendants(),
                  view;

              var circle = svg_#{id}.selectAll("circle")
                .data(nodes)
                .enter().append("circle")
                  .attr("class", (d) => d.parent ? d.children ? "node" : "node file" : "node root")
                  .attr("fill", (d) => d.children ? dirColor(d.data.score) : strictnessColor(d.data.strictness))
                  .attr("fill-opacity", (d) => d.children ? opacity(d.depth) : 1)
                  .on("click", function(d) { if (focus !== d) zoom(d), d3.event.stopPropagation(); })
                  .on("mouseover", (d) => tooltip.style("opacity", 1))
                  .on("mousemove", tooltipMap)
                  .on("mouseleave", (d) => tooltip.style("opacity", 0));

              var text = svg_#{id}.selectAll("text")
                .data(nodes)
                .enter().append("text")
                  .attr("class", (d) => d.children ? "label dir" : "label file")
                  .attr("fill-opacity", (d) => d.depth <= 1 ? 1 : 0)
                  .attr("display", (d) => d.depth <= 1 ? "inline" : "none")
                  .text((d) => d.data.name);

              var node = svg_#{id}.selectAll("circle,text");

              function zoom(d) {
                var focus0 = focus; focus = d;

                var transition = d3.transition()
                    .duration(d3.event.altKey ? 7500 : 750)
                    .tween("zoom", function(d) {
                      var i = d3.interpolateZoom(view, [focus.x, focus.y, focus.r * 2]);
                      return (t) => zoomTo(i(t));
                    });

                transition.selectAll("text")
                  .filter(function(d) { return d && d.parent === focus || this.style.display === "inline"; })
                    .attr("fill-opacity", function(d) { return d.parent === focus ? 1 : 0; })
                    .on("start", function(d) { if (d.parent === focus) this.style.display = "inline"; })
                    .on("end", function(d) { if (d.parent !== focus) this.style.display = "none"; });
              }

              function zoomTo(v) {
                var k = diameter / v[2]; view = v;
                node.attr("transform", (d) => "translate(" + (d.x - v[0]) * k + "," + (d.y - v[1]) * k + ")");
                circle.attr("r", (d) => d.r * k);
              }

              zoomTo([root.x, root.y, root.r * 2]);
              d3.select("##{id}").on("click", () => zoom(root));
            }

            redraw();
            window.addEventListener("resize", redraw);
          JS
        end

        class Sigils < CircleMap
          extend T::Sig

          sig do
            params(
              id: String,
              file_tree: FileTree,
              nodes_strictnesses: T::Hash[FileTree::Node, T.nilable(String)],
              nodes_scores: T::Hash[FileTree::Node, Float],
            ).void
          end
          def initialize(id, file_tree, nodes_strictnesses, nodes_scores)
            @nodes_strictnesses = nodes_strictnesses
            @nodes_scores = nodes_scores
            super(id, file_tree.roots.map { |r| tree_node_to_json(r) })
          end

          sig { params(node: FileTree::Node).returns(T::Hash[Symbol, T.untyped]) }
          def tree_node_to_json(node)
            if node.children.empty?
              {
                name: node.name,
                strictness: @nodes_strictnesses.fetch(node, "false"),
              }
            else
              {
                name: node.name,
                children: node.children.values.map { |n| tree_node_to_json(n) },
                score: @nodes_scores.fetch(node, 0.0),
              }
            end
          end
        end
      end
    end
  end
end
