# typed: strict
# frozen_string_literal: true

require_relative "base"

module Spoom
  module Coverage
    module D3
      class Timeline < Base
        extend T::Sig
        extend T::Helpers

        abstract!

        sig { params(id: String, data: T.untyped, keys: T::Array[String]).void }
        def initialize(id, data, keys)
          super(id, data)
          @keys = keys
        end

        class << self
          extend T::Sig

          sig { returns(String) }
          def header_style
            <<~CSS
              .domain {
                stroke: transparent;
              }

              .grid line {
                stroke: #ccc;
              }

              .axis text {
                font: 12px Arial, sans-serif;
                fill: #333;
                text-anchor: right;
                pointer-events: none;
              }

              .area {
                fill-opacity: 0.5;
              }

              .line {
                stroke-width: 2;
                fill: transparent;
              }

              .dot {
                r: 2;
                fill: #888;
              }

              .inverted .grid line {
                stroke: #777;
              }

              .inverted .area {
                fill-opacity: 0.9;
              }

              .inverted .axis text {
                fill: #fff;
              }

              .inverted .axis line {
                stroke: #fff;
              }

              .inverted .dot {
                fill: #fff;
              }
            CSS
          end

          sig { returns(String) }
          def header_script
            <<~JS
              var parseVersion = function(version) {
                if (!version) {
                  return null;
                }
                return parseFloat(version.replaceAll("0.", ""));
              }

              function tooltipTimeline(d, kind) {
                moveTooltip(d)
                  .html("commit <b>" + d.data.commit + "</b><br>"
                    + d3.timeFormat("%y/%m/%d")(parseDate(d.data.timestamp)) + "<br><br>"
                    + "<b>typed: " + d.key + "</b><br><br>"
                    + "<b>" + (d.data.values[d.key] ? d.data.values[d.key] : 0) + "</b> " + kind +"<br>"
                    + "<b>" + toPercent(d.data.values[d.key] ? d.data.values[d.key] : 0, d.data.total) + "%")
              }
            JS
          end
        end

        sig { override.returns(String) }
        def script
          <<~HTML
            #{tooltip}

            var data_#{id} = #{@data.to_json};

            function draw_#{id}() {
              var width_#{id} = document.getElementById("#{id}").clientWidth;
              var height_#{id} = 200;

              d3.select("##{id}").selectAll("*").remove()

              var svg_#{id} = d3.select("##{id}")
                .attr("width", width_#{id})
                .attr("height", height_#{id})

              #{plot}
            }

            draw_#{id}();
            window.addEventListener("resize", draw_#{id});
          HTML
        end

        sig { abstract.returns(String) }
        def plot; end

        sig { returns(String) }
        def x_scale
          <<~HTML
            var xScale_#{id} = d3.scaleTime()
              .range([0, width_#{id}])
              .domain(d3.extent(data_#{id}, (d) => parseDate(d.timestamp)));

            svg_#{id}.append("g")
              .attr("class", "grid")
              .attr("transform", "translate(0," + height_#{id} + ")")
              .call(d3.axisBottom(xScale_#{id})
                .tickFormat("")
                .tickSize(-height_#{id}))
          HTML
        end

        sig { returns(String) }
        def x_ticks
          <<~HTML
            svg_#{id}.append("g")
              .attr("class", "axis x")
              .attr("transform", "translate(0," + height_#{id} + ")")
              .call(d3.axisBottom(xScale_#{id})
                .tickFormat(d3.timeFormat("%y/%m/%d"))
                .tickPadding(-15)
                .tickSize(-3));
          HTML
        end

        sig { params(min: String, max: String, ticks: String).returns(String) }
        def y_scale(min:, max:, ticks:)
          <<~HTML
            var yScale_#{id} = d3.scaleLinear()
              .range([height_#{id}, 0])
              .domain([#{min}, #{max}]);

            svg_#{id}.append("g")
              .attr("class", "grid")
              .call(d3.axisLeft(yScale_#{id})
                .#{ticks}
                .tickFormat("")
                .tickSize(-width_#{id}))
          HTML
        end

        sig { params(ticks: String, format: String, padding: Integer).returns(String) }
        def y_ticks(ticks:, format:, padding:)
          <<~HTML
            svg_#{id}.append("g")
              .attr("class", "axis y")
              .call(d3.axisLeft(yScale_#{id})
                .#{ticks}
                .tickSize(-3)
                .tickFormat((d) => #{format})
                .tickPadding(-#{padding}))
          HTML
        end

        sig { params(y: String, color: String, curve: String).returns(String) }
        def area(y:, color: "#ccc", curve: "curveCatmullRom.alpha(1)")
          <<~HTML
            svg_#{id}.append("path")
              .datum(data_#{id}.filter((d) => #{y}))
              .attr("class", "area")
              .attr("d", d3.area()
                .defined((d) => #{y})
                .x((d) => xScale_#{id}(parseDate(d.timestamp)))
                .y0(yScale_#{id}(0))
                .y1((d) => yScale_#{id}(#{y}))
                .curve(d3.#{curve}))
              .attr("fill", "#{color}")
          HTML
        end

        sig { params(y: String, color: String, curve: String).returns(String) }
        def line(y:, color: "#ccc", curve: "curveCatmullRom.alpha(1)")
          <<~HTML
            svg_#{id}.append("path")
               .datum(data_#{id}.filter((d) => #{y}))
               .attr("class", "line")
               .attr("d", d3.line()
                 .x((d) => xScale_#{id}(parseDate(d.timestamp)))
                 .y((d) => yScale_#{id}(#{y}))
                 .curve(d3.#{curve}))
               .attr("stroke", "#{color}")
          HTML
        end

        sig { params(y: String).returns(String) }
        def points(y:)
          <<~HTML
            svg_#{id}.selectAll("circle")
              .data(data_#{id})
              .enter()
                .append("circle")
                .attr("class", "dot")
                .attr("cx", (d) => xScale_#{id}(parseDate(d.timestamp)))
                .attr("cy", (d, i) => yScale_#{id}(#{y}))
                .on("mouseover", (d) => tooltip.style("opacity", 1))
                .on("mousemove", tooltip_#{id})
                .on("mouseleave", (d) => tooltip.style("opacity", 0));
          HTML
        end

        class Versions < Timeline
          extend T::Sig

          sig { params(id: String, snapshots: T::Array[Snapshot]).void }
          def initialize(id, snapshots)
            data = snapshots.map do |snapshot|
              {
                timestamp: snapshot.commit_timestamp,
                commit: snapshot.commit_sha,
                static: snapshot.version_static,
                runtime: snapshot.version_runtime,
              }
            end
            super(id, data, [])
          end

          sig { override.returns(String) }
          def tooltip
            <<~JS
              function tooltip_#{id}(d) {
                moveTooltip(d)
                  .html("commit <b>" + d.commit + "</b><br>"
                    + d3.timeFormat("%y/%m/%d")(parseDate(d.timestamp)) + "<br><br>"
                    + "static: v<b>" + d.static + "</b><br>"
                    + "runtime: v<b>" + d.runtime + "</b><br><br>"
                    + "versions from<br>Gemfile.lock")
              }
            JS
          end

          sig { override.returns(String) }
          def plot
            <<~JS
              #{x_scale}
              #{y_scale(
                min: "d3.min([d3.min(data_#{id}, (d) => parseVersion(d.static)),
                              d3.min(data_#{id}, (d) => parseVersion(d.runtime))]) - 0.01",
                max: "d3.max([d3.max(data_#{id}, (d) => parseVersion(d.static)),
                              d3.max(data_#{id}, (d) => parseVersion(d.runtime))]) + 0.01",
                ticks: "ticks(8)",
              )}
              #{line(y: "parseVersion(d.runtime)", color: "#e83e8c", curve: "curveStepAfter")}
              #{line(y: "parseVersion(d.static)", color: "#007bff", curve: "curveStepAfter")}
              #{points(y: "parseVersion(d.static)")}
              #{x_ticks}
              #{y_ticks(ticks: "ticks(4)", format: "'v0.' + d.toFixed(2)", padding: 50)}
            JS
          end
        end

        class Runtimes < Timeline
          extend T::Sig

          sig { params(id: String, snapshots: T::Array[Snapshot]).void }
          def initialize(id, snapshots)
            data = snapshots.map do |snapshot|
              {
                timestamp: snapshot.commit_timestamp,
                commit: snapshot.commit_sha,
                runtime: snapshot.duration.to_f / 1000.0 / 1000.0,
              }
            end
            super(id, data, [])
          end

          sig { override.returns(String) }
          def tooltip
            <<~JS
              function tooltip_#{id}(d) {
                moveTooltip(d)
                  .html("commit <b>" + d.commit + "</b><br>"
                    + d3.timeFormat("%y/%m/%d")(parseDate(d.timestamp)) + "<br><br>"
                    + "<b>" + d.runtime + "</b>s<br><br>"
                    + "(sorbet user + system time)")
              }
            JS
          end

          sig { override.returns(String) }
          def plot
            <<~JS
              #{x_scale}
              #{y_scale(
                min: "0",
                max: "d3.max(data_#{id}, (d) => d.runtime)",
                ticks: "ticks(10)",
              )}
              #{area(y: "d.runtime")}
              #{line(y: "d.runtime")}
              #{points(y: "d.runtime")}
              #{x_ticks}
              #{y_ticks(ticks: "ticks(5)", format: 'd.toFixed(2) + "s"', padding: 40)}
                .call(g => g.selectAll(".tick:first-of-type text").remove())
            JS
          end
        end

        class Stacked < Timeline
          extend T::Sig
          extend T::Helpers

          abstract!

          sig { override.returns(String) }
          def script
            <<~JS
              #{tooltip}

              var data_#{id} = #{@data.to_json};
              var keys_#{id} = #{T.unsafe(@keys).to_json};

              var stack_#{id} = d3.stack()
                .keys(keys_#{id})
                .value((d, key) => toPercent(d.values[key], d.total));

              var layers_#{id} = stack_#{id}(data_#{id});

              var points_#{id} = []
              layers_#{id}.forEach(function(d) {
                d.forEach(function(p) {
                  p.key = d.key
                  points_#{id}.push(p);
                });
              })

              function draw_#{id}() {
                var width_#{id} = document.getElementById("#{id}").clientWidth;
                var height_#{id} = 200;

                d3.select("##{id}").selectAll("*").remove()

                var svg_#{id} = d3.select("##{id}")
                  .attr("class", "inverted")
                  .attr("width", width_#{id})
                  .attr("height", height_#{id});

                #{plot}
              }

              draw_#{id}();
              window.addEventListener("resize", draw_#{id});
            JS
          end

          sig { override.returns(String) }
          def plot
            <<~JS
              #{x_scale}
              #{y_scale(min: "0", max: "100", ticks: "tickValues([0, 25, 50, 75, 100])")}
              #{line(y: "d.data.timestamp")}
              #{x_ticks}
              #{y_ticks(ticks: "tickValues([25, 50, 75])", format: "d + '%'", padding: 30)}
            JS
          end

          sig { override.params(y: String, color: String, curve: String).returns(String) }
          def line(y:, color: "strictnessColor(d.key)", curve: "curveCatmullRom.alpha(1)")
            <<~JS
              var area_#{id} = d3.area()
                .x((d) => xScale_#{id}(parseDate(#{y})))
                .y0((d) => yScale_#{id}(d[0]))
                .y1((d) => yScale_#{id}(d[1]))
                .curve(d3.#{curve});

              var layer = svg_#{id}.selectAll(".layer")
                .data(layers_#{id})
                .enter().append("g")
                  .attr("class", "layer")
                  .attr("fill", (d, i) => #{color})

              layer.append("path")
                .attr("class", "area")
                .attr("d", area_#{id})
                .attr("fill", (d) => #{color})

              svg_#{id}.selectAll("circle")
                .data(points_#{id})
                .enter()
                  .append("circle")
                  .attr("class", "dot")
                  .attr("cx", (d) => xScale_#{id}(parseDate(#{y})))
                  .attr("cy", (d, i) => yScale_#{id}(d[1]))
                  .on("mouseover", (d) => tooltip.style("opacity", 1))
                  .on("mousemove", tooltip_#{id})
                  .on("mouseleave", (d) => tooltip.style("opacity", 0));
            JS
          end
        end

        class Sigils < Stacked
          extend T::Sig

          sig { params(id: String, snapshots: T::Array[Snapshot]).void }
          def initialize(id, snapshots)
            keys = Snapshot::STRICTNESSES
            data = snapshots.map do |snapshot|
              {
                timestamp: snapshot.commit_timestamp,
                commit: snapshot.commit_sha,
                total: snapshot.files - snapshot.rbi_files,
                values: snapshot.sigils_excluding_rbis,
              }
            end
            super(id, data, keys)
          end

          sig { override.returns(String) }
          def tooltip
            <<~JS
              function tooltip_#{id}(d) {
                tooltipTimeline(d, "files excluding RBIs");
              }
            JS
          end
        end

        class Calls < Stacked
          extend T::Sig

          sig { params(id: String, snapshots: T::Array[Snapshot]).void }
          def initialize(id, snapshots)
            keys = ["false", "true"]
            data = snapshots.map do |snapshot|
              {
                timestamp: snapshot.commit_timestamp,
                commit: snapshot.commit_sha,
                total: snapshot.calls_typed + snapshot.calls_untyped,
                values: { true: snapshot.calls_typed, false: snapshot.calls_untyped },
              }
            end
            super(id, data, keys)
          end

          sig { override.returns(String) }
          def tooltip
            <<~JS
              function tooltip_#{id}(d) {
                tooltipTimeline(d, "calls");
              }
            JS
          end
        end

        class Sigs < Stacked
          extend T::Sig

          sig { params(id: String, snapshots: T::Array[Snapshot]).void }
          def initialize(id, snapshots)
            keys = ["false", "true"]
            data = snapshots.map do |snapshot|
              {
                timestamp: snapshot.commit_timestamp,
                commit: snapshot.commit_sha,
                total: snapshot.methods_with_sig_excluding_rbis + snapshot.methods_without_sig_excluding_rbis,
                values: {
                  true: snapshot.methods_with_sig_excluding_rbis,
                  false: snapshot.methods_without_sig_excluding_rbis,
                },
              }
            end
            super(id, data, keys)
          end

          sig { override.returns(String) }
          def tooltip
            <<~JS
              function tooltip_#{id}(d) {
                tooltipTimeline(d, "methods excluding RBIs");
              }
            JS
          end
        end

        class RBIs < Stacked
          extend T::Sig

          sig { params(id: String, snapshots: T::Array[Snapshot]).void }
          def initialize(id, snapshots)
            keys = ["rbis", "files"]
            data = snapshots.map do |snapshot|
              {
                timestamp: snapshot.commit_timestamp,
                commit: snapshot.commit_sha,
                total: snapshot.files,
                values: { files: snapshot.files - snapshot.rbi_files, rbis: snapshot.rbi_files },
              }
            end
            super(id, data, keys)
          end

          sig { override.returns(String) }
          def tooltip
            <<~JS
              function tooltip_#{id}(d) {
                moveTooltip(d)
                  .html("commit <b>" + d.data.commit + "</b><br>"
                    + d3.timeFormat("%y/%m/%d")(parseDate(d.data.timestamp)) + "<br><br>"
                    + "Files: <b>" + d.data.values.files + "</b><br>"
                    + "RBIs: <b>" + d.data.values.rbis + "</b><br><br>"
                    + "Total: <b>" + d.data.total + "</b>")
              }
            JS
          end

          sig { override.returns(String) }
          def script
            <<~JS
              #{tooltip}

              var data_#{id} = #{@data.to_json};
              var keys_#{id} = #{T.unsafe(@keys).to_json};

              var stack_#{id} = d3.stack()
                .keys(keys_#{id})
                .value((d, key) => d.values[key]);

              var layers_#{id} = stack_#{id}(data_#{id});

              var points_#{id} = []
              layers_#{id}.forEach(function(d) {
                d.forEach(function(p) {
                  p.key = d.key
                  points_#{id}.push(p);
                });
              })

              function draw_#{id}() {
                var width_#{id} = document.getElementById("#{id}").clientWidth;
                var height_#{id} = 200;

                d3.select("##{id}").selectAll("*").remove()

                var svg_#{id} = d3.select("##{id}")
                  .attr("width", width_#{id})
                  .attr("height", height_#{id});

                #{plot}
              }

              draw_#{id}();
              window.addEventListener("resize", draw_#{id});
            JS
          end

          sig { override.params(y: String, color: String, curve: String).returns(String) }
          def line(y:, color: "strictnessColor(d.key)", curve: "curveCatmullRom.alpha(1)")
            <<~JS
              var area_#{id} = d3.area()
                .x((d) => xScale_#{id}(parseDate(#{y})))
                .y0((d) => yScale_#{id}(d[0]))
                .y1((d) => yScale_#{id}(d[1]))
                .curve(d3.#{curve});

              var layer = svg_#{id}.selectAll(".layer")
                .data(layers_#{id})
                .enter().append("g")
                  .attr("class", "layer")

              layer.append("path")
                .attr("class", "area")
                .attr("d", area_#{id})
                .attr("fill", (d) => #{color})

              layer.append("path")
                .attr("class", "line")
                .attr("d", d3.line()
                  .x((d) => xScale_#{id}(parseDate(#{y})))
                  .y((d, i) => yScale_#{id}(d[1]))
                  .curve(d3.#{curve}))
                .attr("stroke", (d) => #{color})

              svg_#{id}.selectAll("circle")
                .data(points_#{id})
                .enter()
                  .append("circle")
                  .attr("class", "dot")
                  .attr("cx", (d) => xScale_#{id}(parseDate(#{y})))
                  .attr("cy", (d, i) => yScale_#{id}(d[1]))
                  .on("mouseover", (d) => tooltip.style("opacity", 1))
                  .on("mousemove", tooltip_#{id})
                  .on("mouseleave", (d) => tooltip.style("opacity", 0));
            JS
          end

          sig { override.returns(String) }
          def plot
            <<~JS
              #{x_scale}
              #{y_scale(min: "0", max: "d3.max(data_#{id}, (d) => d.total + 10)", ticks: "tickValues([0, 25, 50, 75, 100])")}
              #{line(y: "d.data.timestamp", color: "d.key == 'rbis' ? '#8673ff' : '#007bff'")}
              #{x_ticks}
              #{y_ticks(ticks: "tickValues([25, 50, 75])", format: "d", padding: 20)}
            JS
          end
        end
      end
    end
  end
end
