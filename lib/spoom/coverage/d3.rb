# typed: strict
# frozen_string_literal: true

require_relative "d3/circle_map"
require_relative "d3/pie"
require_relative "d3/timeline"

module Spoom
  module Coverage
    module D3
      COLOR_IGNORE = "#999"
      COLOR_FALSE = "#db4437"
      COLOR_TRUE = "#0f9d58"
      COLOR_STRICT = "#0a7340"
      COLOR_STRONG = "#064828"

      class << self
        extend T::Sig

        sig { returns(String) }
        def header_style
          <<~CSS
            svg {
              width: 100%;
              height: 100%;
            }

            .tooltip {
              font: 12px Arial, sans-serif;
              color: #fff;
              text-align: center;
              background: rgba(0, 0, 0, 0.6);
              padding: 5px;
              border: 0px;
              border-radius: 4px;
              position: absolute;
              top: 0;
              left: 0;
              opacity: 0;
            }

            .label {
              font: 14px Arial, sans-serif;
              font-weight: bold;
              fill: #fff;
              text-anchor: middle;
              pointer-events: none;
            }

            .label .small {
              font-size: 10px;
            }

            #{Pie.header_style}
            #{CircleMap.header_style}
            #{Timeline.header_style}
          CSS
        end

        sig { params(palette: ColorPalette).returns(String) }
        def header_script(palette)
          <<~JS
            var parseDate = d3.timeParse("%s");

            function strictnessColor(strictness) {
              switch(strictness) {
                case "ignore":
                  return "#{palette.ignore}";
                case "false":
                  return "#{palette.false}";
                case "true":
                  return "#{palette.true}";
                case "strict":
                  return "#{palette.strict}";
                case "strong":
                  return "#{palette.strong}";
              }
              return "#{palette.false}";
            }

            function toPercent(value, sum) {
              return value ? Math.round(value * 100 / sum) : 0;
            }

            var tooltip = d3.select("body")
              .append("div")
                .append("div")
                  .attr("class", "tooltip");

            function moveTooltip(d) {
              return tooltip
                .style("left", (d3.event.pageX + 20) + "px")
                .style("top", (d3.event.pageY) + "px")
            }

            #{Pie.header_script}
            #{CircleMap.header_script}
            #{Timeline.header_script}
          JS
        end
      end

      class ColorPalette < T::Struct
        prop :ignore, String
        prop :false, String
        prop :true, String
        prop :strict, String
        prop :strong, String
      end
    end
  end
end
