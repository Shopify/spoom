# typed: strict
# frozen_string_literal: true

module Spoom
  module Sorbet
    class Metrics < T::Struct
      extend T::Sig

      DEFAULT_PREFIX = "ruby_typer.unknown.."
      SIGILS = T.let(["ignore", "false", "true", "strict", "strong", "__STDLIB_INTERNAL"], T::Array[String])

      const :repo, String
      const :sha, String
      const :status, String
      const :branch, String
      const :timestamp, Integer
      const :uuid, String
      const :metrics, T::Hash[String, T.nilable(Integer)]

      sig { params(path: String, prefix: String).returns(Metrics) }
      def self.parse_file(path, prefix = DEFAULT_PREFIX)
        parse_string(File.read(path), prefix)
      end

      sig { params(string: String, prefix: String).returns(Metrics) }
      def self.parse_string(string, prefix = DEFAULT_PREFIX)
        parse_hash(JSON.parse(string), prefix)
      end

      sig { params(obj: T::Hash[String, T.untyped], prefix: String).returns(Metrics) }
      def self.parse_hash(obj, prefix = DEFAULT_PREFIX)
        Metrics.new(
          repo: obj.fetch("repo"),
          sha: obj.fetch("sha"),
          status: obj.fetch("status"),
          branch: obj.fetch("branch"),
          timestamp: obj.fetch("timestamp").to_i,
          uuid: obj.fetch("uuid"),
          metrics: obj["metrics"].each_with_object({}) do |metric, all|
            name = metric["name"]
            name = name.sub(prefix, '')
            all[name] = metric["value"].to_i
          end,
        )
      end

      sig { returns(T::Hash[String, T.nilable(Integer)]) }
      def files_by_strictness
        SIGILS.each_with_object({}) do |sigil, map|
          map[sigil] = metrics["types.input.files.sigil.#{sigil}"]
        end
      end

      sig { returns(Integer) }
      def files_count
        files_by_strictness.values.compact.sum
      end

      sig { params(key: String).returns(T.nilable(Integer)) }
      def [](key)
        metrics[key]
      end

      sig { returns(String) }
      def to_s
        "Metrics<#{repo}-#{timestamp}-#{status}>"
      end

      sig { params(out: T.any(IO, StringIO)).void }
      def show(out = $stdout)
        files = files_count

        out.puts "Sigils:"
        out.puts "  files: #{files}"
        files_by_strictness.each do |sigil, value|
          next unless value
          out.puts "  #{sigil}: #{value}#{percent(value, files)}"
        end

        out.puts "\nMethods:"
        m = metrics['types.input.methods.total']
        s = metrics['types.sig.count']
        out.puts "  methods: #{m}"
        out.puts "  signatures: #{s}#{percent(s, m)}"

        out.puts "\nSends:"
        t = metrics['types.input.sends.typed']
        s = metrics['types.input.sends.total']
        out.puts "  sends: #{s}"
        out.puts "  typed: #{t}#{percent(t, s)}"
      end

      private

      sig { params(value: T.nilable(Integer), total: T.nilable(Integer)).returns(String) }
      def percent(value, total)
        return "" if value.nil? || total.nil? || total == 0
        " (#{value * 100 / total}%)"
      end
    end
  end
end
