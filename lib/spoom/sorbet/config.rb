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
      extend T::Sig

      sig { returns(T::Array[String]) }
      attr_reader :paths, :ignore, :allowed_extensions

      sig { void }
      def initialize
        @paths = T.let([], T::Array[String])
        @ignore = T.let([], T::Array[String])
        @allowed_extensions = T.let([], T::Array[String])
      end

      class << self
        extend T::Sig

        sig { params(sorbet_config_path: String).returns(Spoom::Sorbet::Config) }
        def parse_file(sorbet_config_path)
          parse_string(File.read(sorbet_config_path))
        end

        sig { params(sorbet_config: String).returns(Spoom::Sorbet::Config) }
        def parse_string(sorbet_config)
          config = Config.new
          state = T.let(nil, T.nilable(Symbol))
          sorbet_config.each_line do |line|
            line = line.strip
            case line
            when /^--allowed-extension$/
              state = :extension
              next
            when /^--allowed-extension=/
              config.allowed_extensions << parse_option(line)
              next
            when /^--ignore=/
              config.ignore << parse_option(line)
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
            when /^--.*=/
              next
            when /^--/
              state = :skip
            when /^-.*=?/
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

        sig { params(line: String).returns(String) }
        def parse_option(line)
          T.must(line.split("=").last).strip
        end
      end
    end
  end
end
