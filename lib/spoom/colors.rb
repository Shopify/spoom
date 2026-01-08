# typed: strict
# frozen_string_literal: true

module Spoom
  class Color
    #: String
    attr_reader :ansi_code

    #: (String) -> void
    def initialize(ansi_code)
      @ansi_code = ansi_code
    end

    CLEAR           = new("\e[0m") #: Color
    BOLD            = new("\e[1m") #: Color

    BLACK           = new("\e[30m") #: Color
    RED             = new("\e[31m") #: Color
    GREEN           = new("\e[32m") #: Color
    YELLOW          = new("\e[33m") #: Color
    BLUE            = new("\e[34m") #: Color
    MAGENTA         = new("\e[35m") #: Color
    CYAN            = new("\e[36m") #: Color
    WHITE           = new("\e[37m") #: Color

    LIGHT_BLACK     = new("\e[90m") #: Color
    LIGHT_RED       = new("\e[91m") #: Color
    LIGHT_GREEN     = new("\e[92m") #: Color
    LIGHT_YELLOW    = new("\e[93m") #: Color
    LIGHT_BLUE      = new("\e[94m") #: Color
    LIGHT_MAGENTA   = new("\e[95m") #: Color
    LIGHT_CYAN      = new("\e[96m") #: Color
    LIGHT_WHITE     = new("\e[97m") #: Color
  end

  module Colorize
    #: (String string, *Color color) -> String
    def set_color(string, *color)
      "#{color.map(&:ansi_code).join}#{string}#{Color::CLEAR.ansi_code}"
    end
  end
end
