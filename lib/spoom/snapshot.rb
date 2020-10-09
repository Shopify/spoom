# typed: strict
# frozen_string_literal: true

module Spoom
  module Coverage
    extend T::Sig

    sig { params(path: String).returns(Snapshot) }
    def self.snapshot(path: '.')
      snapshot = Snapshot.new
      metrics = Spoom::Sorbet.srb_metrics(path: path, capture_err: true)
      return snapshot unless metrics

      sha = Spoom::Git.last_commit(path: path)
      snapshot.commit_sha = sha
      snapshot.commit_timestamp = Spoom::Git.commit_timestamp(sha, path: path).to_i if sha

      snapshot.files = metrics.fetch("types.input.files", 0)
      snapshot.modules = metrics.fetch("types.input.modules.total", 0)
      snapshot.classes = metrics.fetch("types.input.classes.total", 0)
      snapshot.methods_with_sig = metrics.fetch("types.sig.count", 0)
      snapshot.methods_without_sig = metrics.fetch("types.input.methods.total", 0) - snapshot.methods_with_sig
      snapshot.calls_typed = metrics.fetch("types.input.sends.typed", 0)
      snapshot.calls_untyped = metrics.fetch("types.input.sends.total", 0) - snapshot.calls_typed

      snapshot.duration += metrics.fetch("run.utilization.system_time.us", 0)
      snapshot.duration += metrics.fetch("run.utilization.user_time.us", 0)

      Snapshot::STRICTNESSES.each do |strictness|
        next unless metrics.key?("types.input.files.sigil.#{strictness}")
        snapshot.sigils[strictness] = T.must(metrics["types.input.files.sigil.#{strictness}"])
      end

      snapshot.sorbet_version = Spoom::Sorbet.version_from_gemfile_lock(path: path)

      snapshot
    end

    class Snapshot < T::Struct
      extend T::Sig

      prop :timestamp, Integer, default: Time.new.getutc.to_i
      prop :sorbet_version, T.nilable(String), default: nil
      prop :duration, Integer, default: 0
      prop :commit_sha, T.nilable(String), default: nil
      prop :commit_timestamp, T.nilable(Integer), default: nil
      prop :files, Integer, default: 0
      prop :modules, Integer, default: 0
      prop :classes, Integer, default: 0
      prop :methods_without_sig, Integer, default: 0
      prop :methods_with_sig, Integer, default: 0
      prop :calls_untyped, Integer, default: 0
      prop :calls_typed, Integer, default: 0
      prop :sigils, T::Hash[String, Integer], default: Hash.new(0)

      # The strictness name as found in the Sorbet metrics file
      STRICTNESSES = T.let(["ignore", "false", "true", "strict", "strong", "stdlib"].freeze, T::Array[String])

      sig { params(out: T.any(IO, StringIO), colors: T::Boolean, indent_level: Integer).void }
      def print(out: $stdout, colors: true, indent_level: 0)
        printer = SnapshotPrinter.new(out: out, colors: colors, indent_level: indent_level)
        printer.print_snapshot(self)
      end

      sig { params(json: String).returns(Snapshot) }
      def self.from_json(json)
        from_obj(JSON.parse(json))
      end

      sig { params(obj: T::Hash[String, T.untyped]).returns(Snapshot) }
      def self.from_obj(obj)
        snapshot = Snapshot.new
        snapshot.timestamp = obj.fetch("timestamp", 0)
        snapshot.sorbet_version = obj.fetch("sorbet_version", nil)
        snapshot.duration = obj.fetch("duration", 0)
        snapshot.commit_sha = obj.fetch("commit_sha", nil)
        snapshot.commit_timestamp = obj.fetch("commit_timestamp", nil)
        snapshot.files = obj.fetch("files", 0)
        snapshot.modules = obj.fetch("modules", 0)
        snapshot.classes = obj.fetch("classes", 0)
        snapshot.methods_with_sig = obj.fetch("methods_with_sig", 0)
        snapshot.methods_without_sig = obj.fetch("methods_without_sig", 0)
        snapshot.calls_typed = obj.fetch("calls_typed", 0)
        snapshot.calls_untyped = obj.fetch("calls_untyped", 0)

        sigils = obj.fetch("sigils", {})
        if sigils
          Snapshot::STRICTNESSES.each do |strictness|
            next unless sigils.key?(strictness)
            snapshot.sigils[strictness] = sigils[strictness]
          end
        end

        snapshot
      end

      sig { params(arg: T.untyped).returns(String) }
      def to_json(*arg)
        serialize.to_json(*arg)
      end
    end

    class SnapshotPrinter < Spoom::Printer
      extend T::Sig

      sig { params(snapshot: Snapshot).void }
      def print_snapshot(snapshot)
        methods = snapshot.methods_with_sig + snapshot.methods_without_sig
        calls = snapshot.calls_typed + snapshot.calls_untyped

        if snapshot.sorbet_version
          printl("Sorbet version: #{snapshot.sorbet_version}")
          printn
        end
        printl("Content:")
        indent
        printl("files: #{snapshot.files}")
        printl("modules: #{snapshot.modules}")
        printl("classes: #{snapshot.classes} (including singleton classes)")
        printl("methods: #{methods}")
        dedent
        printn
        printl("Sigils:")
        print_map(snapshot.sigils, snapshot.files)
        printn
        printl("Methods:")
        methods_map = {
          "with signature" => snapshot.methods_with_sig,
          "without signature" => snapshot.methods_without_sig,
        }
        print_map(methods_map, methods)
        printn
        printl("Calls:")
        calls_map = {
          "typed" => snapshot.calls_typed,
          "untyped" => snapshot.calls_untyped,
        }
        print_map(calls_map, calls)
      end

      private

      sig { params(hash: T::Hash[String, Integer], total: Integer).void }
      def print_map(hash, total)
        indent
        hash.each do |key, value|
          next unless value > 0
          printl("#{key}: #{value}#{percent(value, total)}")
        end
        dedent
      end

      sig { params(value: T.nilable(Integer), total: T.nilable(Integer)).returns(String) }
      def percent(value, total)
        return "" if value.nil? || total.nil? || total == 0
        " (#{(value.to_f * 100.0 / total.to_f).round}%)"
      end
    end
  end
end
