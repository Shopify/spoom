# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    # Parse Sorbet config files
    #
    # Parses a Sorbet config file:
    #
    # ```ruby
    # config = Spoom::Sorbet::Config.parse_file("sorbet/config")
    # puts config.paths   # "."
    # ```
    #
    # Parses a Sorbet config string:
    #
    # ```ruby
    # config = Spoom::Sorbet::Config.parse_string(<<~CONFIG)
    #   a
    #   --file=b
    #   --ignore=c
    # CONFIG
    # puts config.paths   # "a", "b"
    # puts config.ignore  # "c"
    # ```
    class Config
      DEFAULT_ALLOWED_EXTENSIONS = [".rb", ".rbi"].freeze #: Array[String]

      #: Array[String]
      attr_accessor :paths, :ignore, :allowed_extensions

      #: bool
      attr_accessor :no_stdlib

      #: String?
      attr_accessor :cache_dir

      #: Symbol?
      attr_accessor :parser

      #: bool
      attr_accessor :use_rbs

      #: -> bool
      def parse_with_prism? = @parser == :prism

      #: -> bool
      def use_rbs? = @use_rbs

      #: -> void
      def initialize
        @paths = [] #: Array[String]
        @ignore = [] #: Array[String]
        @allowed_extensions = [] #: Array[String]
        @no_stdlib = false #: bool
        @cache_dir = nil #: String?
        @parser = nil #: Symbol?
        @use_rbs = false #: bool
      end

      #: -> Config
      def copy
        new_config = Sorbet::Config.new
        new_config.paths.concat(@paths)
        new_config.ignore.concat(@ignore)
        new_config.allowed_extensions.concat(@allowed_extensions)
        new_config.no_stdlib = @no_stdlib
        new_config.cache_dir = @cache_dir
        new_config.parser = @parser
        new_config.use_rbs = @use_rbs
        new_config
      end

      # Returns self as a string of options that can be passed to Sorbet
      #
      # Example:
      # ~~~rb
      # config = Sorbet::Config.new
      # config.paths << "/foo"
      # config.paths << "/bar"
      # config.ignore << "/baz"
      # config.allowed_extensions << ".rb"
      #
      # puts config.options_string # "/foo /bar --ignore /baz --allowed-extension .rb"
      # ~~~
      #: -> String
      def options_string
        opts = []
        opts.concat(paths.map { |p| "'#{p}'" })
        opts.concat(ignore.map { |p| "--ignore '#{p}'" })
        opts.concat(allowed_extensions.map { |ext| "--allowed-extension '#{ext}'" })
        opts << "--no-stdlib" if @no_stdlib
        opts << "--cache-dir='#{@cache_dir}'" if @cache_dir
        opts << "--parser=#{@parser}" if @parser
        opts.join(" ")
      end

      class << self
        #: (String sorbet_config_path) -> Spoom::Sorbet::Config
        def parse_file(sorbet_config_path)
          parse_string(File.read(sorbet_config_path))
        end

        #: (String sorbet_config) -> Spoom::Sorbet::Config
        def parse_string(sorbet_config)
          config = Config.new
          state = nil #: Symbol?
          sorbet_config.each_line do |line|
            line = line.strip
            case line
            when /^--allowed-extension$/
              state = :extension
              next
            when /^--allowed-extension=/
              config.allowed_extensions << parse_option(line)
              next
            when /^--ignore$/
              state = :ignore
              next
            when /^--ignore=/
              config.ignore << parse_option(line)
              next
            when /^--file$/
              next
            when /^--file=/
              config.paths << parse_option(line)
              next
            when /^--dir$/
              next
            when /^--dir=/
              config.paths << parse_option(line)
              next
            when /^--no-stdlib(=|$)/
              config.no_stdlib = parse_bool_option(line)
              next
            when /^--cache-dir=/
              value = parse_option(line)
              config.cache_dir = value.empty? ? nil : value
              next
            when /^--parser=/
              config.parser = parse_option(line).to_sym
              next
            when /^--enable-experimental-rbs-(comments|signatures|assertions)(=|$)/
              config.use_rbs = parse_bool_option(line)
              next
            when /^--.*=/
              next
            when /^--/
              state = :skip
            when /^-.*=?/
              next
            when /^#/
              next
            when /^$/
              next
            else
              case state
              when :ignore
                config.ignore << line
              when :extension
                config.allowed_extensions << line
              when :skip
                # nothing
              else
                config.paths << line
              end
              state = nil
            end
          end
          config
        end

        private

        #: (String line) -> String
        def parse_option(line)
          T.must(line.split("=", 2).last).strip
        end

        #: (String line) -> bool
        def parse_bool_option(line)
          return true unless line.include?("=") # `--foo` is equivalent to `--foo=true`

          case parse_option(line)
          when "true", "True", "t", "T", "1" then true
          when "false", "False", "f", "F", "0" then false
          else raise ArgumentError, "invalid boolean value: #{parse_option(line).inspect}"
          end
        end
      end
    end
  end
end
