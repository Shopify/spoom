# typed: strict
# frozen_string_literal: true

require_relative "base"

module Spoom
  module Coverage
    module D3
      class Pie < Base
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { params(id: String, title: String, data: T.untyped).void }
        def initialize(id, title, data)
          super(id, data)
          @title = title
        end

        class << self
          extend T::Sig

          sig { returns(String) }
          def header_style
            <<~CSS
              .pie .title {
                font: 18px Arial, sans-serif;
                font-weight: bold;
                fill: #212529;
                text-anchor: middle;
                pointer-events: none;
              }

              .pie .arc {
                stroke: #fff;
                stroke-width: 2px;
              }
            CSS
          end

          sig { returns(String) }
          def header_script
            <<~JS
              function tooltipPie(d, title, kind, sum) {
                moveTooltip(d)
                  .html("<b>" + title + "</b><br><br>"
                    + "<b>" + d.data.value + "</b> " + kind + "<br>"
                    + "<b>" + toPercent(d.data.value, sum) + "</b>%")
              }
            JS
          end
        end

        sig { override.returns(String) }
        def script
          <<~JS
            #{tooltip}

            var json_#{id} = #{@data.to_json};
            var pie_#{id} = d3.pie().value((d) => d.value);
            var data_#{id} = pie_#{id}(d3.entries(json_#{id}));
            var sum_#{id} = d3.sum(data_#{id}, (d) => d.data.value);
            var title_#{id} = #{@title.to_json};

            function draw_#{id}() {
              var pieSize_#{id} = document.getElementById("#{id}").clientWidth - 10;

              var arcGenerator_#{id} = d3.arc()
                .innerRadius(pieSize_#{id} / 4)
                .outerRadius(pieSize_#{id} / 2);

              d3.select("##{id}").selectAll("*").remove()

              var svg_#{id} = d3.select("##{id}")
                .attr("width", pieSize_#{id})
                .attr("height", pieSize_#{id})
                .attr("class", "pie")
                .append("g")
                  .attr("transform", "translate(" + pieSize_#{id} / 2 + "," + pieSize_#{id} / 2 + ")");

              svg_#{id}.selectAll("arcs")
                .data(data_#{id})
                .enter()
                  .append('path')
                    .attr("class", "arc")
                    .attr('fill', (d) => strictnessColor(d.data.key))
                    .attr('d', arcGenerator_#{id})
                    .on("mouseover", (d) => tooltip.style("opacity", 1))
                    .on("mousemove", tooltip_#{id})
                    .on("mouseleave", (d) => tooltip.style("opacity", 0));

              svg_#{id}.selectAll("labels")
                .data(data_#{id})
                .enter()
                  .append('text')
                  .attr("class", "label")
                  .attr("transform", (d) => "translate(" + arcGenerator_#{id}.centroid(d) + ")")
                  .filter(d => (d.endAngle - d.startAngle) > 0.25)
                    .append("tspan")
                    .attr("x", 0)
                    .attr("y", -3)
                    .text((d) => d.data.value)
                      .append("tspan")
                      .attr("class", "small")
                      .attr("x", 0)
                      .attr("y", 13)
                      .text((d) => toPercent(d.data.value, sum_#{id}) + "%");

              svg_#{id}
                .append("text")
                .attr("class", "title")
                .append("tspan")
                  .attr("y", 7)
                  .text(title_#{id});
            }

            draw_#{id}();
            window.addEventListener("resize", draw_#{id});
          JS
        end

        class Sigils < Pie
          extend T::Sig

          sig { params(id: String, title: String, snapshot: Snapshot).void }
          def initialize(id, title, snapshot)
            super(id, title, snapshot.sigils_excluding_rbis.select { |_k, v| v })
          end

          sig { override.returns(String) }
          def tooltip
            <<~JS
              function tooltip_#{id}(d) {
                tooltipPie(d, "typed: " + d.data.key, "files excluding RBIs", sum_#{id});
              }
            JS
          end
        end

        class Calls < Pie
          extend T::Sig

          sig { params(id: String, title: String, snapshot: Snapshot).void }
          def initialize(id, title, snapshot)
            super(id, title, { true: snapshot.calls_typed, false: snapshot.calls_untyped })
          end

          sig { override.returns(String) }
          def tooltip
            <<~JS
              function tooltip_#{id}(d) {
                tooltipPie(d, d.data.key == "true" ? " checked" : " unchecked", "calls", sum_#{id})
              }
            JS
          end
        end

        class Sigs < Pie
          extend T::Sig

          sig { params(id: String, title: String, snapshot: Snapshot).void }
          def initialize(id, title, snapshot)
            super(
              id,
              title,
              { true: snapshot.methods_with_sig_excluding_rbis, false: snapshot.methods_without_sig_excluding_rbis }
            )
          end

          sig { override.returns(String) }
          def tooltip
            <<~JS
              function tooltip_#{id}(d) {
                tooltipPie(
                  d,
                  (d.data.key == "true" ? " with" : " without") + " a signature", "methods excluding RBIs", sum_#{id}
                )
              }
            JS
          end
        end
      end
    end
  end
end
