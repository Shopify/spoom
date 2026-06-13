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
      attr_reader :paths, :ignore, :allowed_extensions

      #: bool
      attr_reader :no_stdlib

      #: (?paths: Array[String], ?ignore: Array[String], ?allowed_extensions: Array[String], ?no_stdlib: bool) -> void
      def initialize(paths: [], ignore: [], allowed_extensions: [], no_stdlib: false)
        @paths = paths
        @ignore = ignore
        @allowed_extensions = allowed_extensions
        @no_stdlib = no_stdlib
      end

      #: (Config source) -> void
      def initialize_copy(source)
        super
        @paths = @paths.dup
        @ignore = @ignore.dup
        @allowed_extensions = @allowed_extensions.dup
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
        opts.join(" ")
      end

      class << self
        #: (String sorbet_config_path) -> Spoom::Sorbet::Config
        def parse_file(sorbet_config_path)
          parse_string(File.read(sorbet_config_path))
        end

        #: (String sorbet_config) -> Spoom::Sorbet::Config
        def parse_string(sorbet_config)
          paths = [] #: Array[String]
          ignore = [] #: Array[String]
          allowed_extensions = [] #: Array[String]
          no_stdlib = false #: bool

          state = nil #: Symbol?

          sorbet_config.each_line do |line|
            line = line.strip
            case line
            when /^--allowed-extension$/
              state = :extension
              next
            when /^--allowed-extension=/
              allowed_extensions << parse_option(line)
              next
            when /^--ignore$/
              state = :ignore
              next
            when /^--ignore=/
              ignore << parse_option(line)
              next
            when /^--file$/
              next
            when /^--file=/
              paths << parse_option(line)
              next
            when /^--dir$/
              next
            when /^--dir=/
              paths << parse_option(line)
              next
            when /^--no-stdlib(=|$)/
              no_stdlib = parse_bool_option(line)
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
                ignore << line
              when :extension
                allowed_extensions << line
              when :skip
                # nothing
              else
                paths << line
              end
              state = nil
            end
          end

          Config.new(
            paths:,
            ignore:,
            allowed_extensions:,
            no_stdlib:,
          )
        end

        private

        #: (String line) -> String
        def parse_option(line)
          T.must(line.split("=").last).strip
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
