# typed: strict
# frozen_string_literal: true

module Spoom
  module Coverage
    class Snapshot
      #: Integer
      attr_accessor :timestamp

      #: String?
      attr_accessor :version_static

      #: String?
      attr_accessor :version_runtime

      #: Integer
      attr_accessor :duration

      #: String?
      attr_accessor :commit_sha

      #: Integer?
      attr_accessor :commit_timestamp

      #: Integer
      attr_accessor :files

      #: Integer
      attr_accessor :rbi_files

      #: Integer
      attr_accessor :modules

      #: Integer
      attr_accessor :classes

      #: Integer
      attr_accessor :singleton_classes

      #: Integer
      attr_accessor :methods_without_sig

      #: Integer
      attr_accessor :methods_with_sig

      #: Integer
      attr_accessor :calls_untyped

      #: Integer
      attr_accessor :calls_typed

      #: Hash[String, Integer]
      attr_accessor :sigils

      #: Integer
      attr_accessor :methods_with_sig_excluding_rbis

      #: Integer
      attr_accessor :methods_without_sig_excluding_rbis

      #: Hash[String, Integer]
      attr_accessor :sigils_excluding_rbis

      #: (
      #|   ?timestamp: Integer,
      #|   ?version_static: String?,
      #|   ?version_runtime: String?,
      #|   ?duration: Integer,
      #|   ?commit_sha: String?,
      #|   ?commit_timestamp: Integer?,
      #|   ?files: Integer,
      #|   ?rbi_files: Integer,
      #|   ?modules: Integer,
      #|   ?classes: Integer,
      #|   ?singleton_classes: Integer,
      #|   ?methods_without_sig: Integer,
      #|   ?methods_with_sig: Integer,
      #|   ?calls_untyped: Integer,
      #|   ?calls_typed: Integer,
      #|   ?sigils: Hash[String, Integer],
      #|   ?methods_with_sig_excluding_rbis: Integer,
      #|   ?methods_without_sig_excluding_rbis: Integer,
      #|   ?sigils_excluding_rbis: Hash[String, Integer],
      #|  ) -> void
      def initialize(
        timestamp: Time.new.getutc.to_i,
        version_static: nil,
        version_runtime: nil,
        duration: 0,
        commit_sha: nil,
        commit_timestamp: nil,
        files: 0,
        rbi_files: 0,
        modules: 0,
        classes: 0,
        singleton_classes: 0,
        methods_without_sig: 0,
        methods_with_sig: 0,
        calls_untyped: 0,
        calls_typed: 0,
        sigils: Hash.new(0),
        methods_with_sig_excluding_rbis: 0,
        methods_without_sig_excluding_rbis: 0,
        sigils_excluding_rbis: Hash.new(0)
      )
        @timestamp = timestamp
        @version_static = version_static
        @version_runtime = version_runtime
        @duration = duration
        @commit_sha = commit_sha
        @commit_timestamp = commit_timestamp
        @files = files
        @rbi_files = rbi_files
        @modules = modules
        @classes = classes
        @singleton_classes = singleton_classes
        @methods_without_sig = methods_without_sig
        @methods_with_sig = methods_with_sig
        @calls_untyped = calls_untyped
        @calls_typed = calls_typed
        @sigils = sigils
        @methods_with_sig_excluding_rbis = methods_with_sig_excluding_rbis
        @methods_without_sig_excluding_rbis = methods_without_sig_excluding_rbis
        @sigils_excluding_rbis = sigils_excluding_rbis
      end

      # The strictness name as found in the Sorbet metrics file
      STRICTNESSES = ["ignore", "false", "true", "strict", "strong", "stdlib"].freeze #: Array[String]

      #: (?out: (IO | StringIO), ?colors: bool, ?indent_level: Integer) -> void
      def print(out: $stdout, colors: true, indent_level: 0)
        printer = SnapshotPrinter.new(out: out, colors: colors, indent_level: indent_level)
        printer.print_snapshot(self)
      end

      #: (*untyped arg) -> String
      def to_json(*arg)
        to_h #: untyped
          .to_json(*arg)
      end

      #: -> Hash[String, untyped]
      def to_h
        {
          "timestamp" => timestamp,
          "version_static" => version_static,
          "version_runtime" => version_runtime,
          "duration" => duration,
          "commit_sha" => commit_sha,
          "commit_timestamp" => commit_timestamp,
          "files" => files,
          "rbi_files" => rbi_files,
          "modules" => modules,
          "classes" => classes,
          "singleton_classes" => singleton_classes,
          "methods_with_sig" => methods_with_sig,
          "methods_without_sig" => methods_without_sig,
          "calls_typed" => calls_typed,
          "calls_untyped" => calls_untyped,
          "sigils" => sigils,
          "methods_with_sig_excluding_rbis" => methods_with_sig_excluding_rbis,
          "methods_without_sig_excluding_rbis" => methods_without_sig_excluding_rbis,
          "sigils_excluding_rbis" => sigils_excluding_rbis,
        }
      end

      class << self
        #: (String json) -> Snapshot
        def from_json(json)
          from_obj(JSON.parse(json))
        end

        #: (Hash[String, untyped] obj) -> Snapshot
        def from_obj(obj)
          snapshot = Snapshot.new
          snapshot.timestamp = obj.fetch("timestamp", 0)
          snapshot.version_static = obj.fetch("version_static", nil)
          snapshot.version_runtime = obj.fetch("version_runtime", nil)
          snapshot.duration = obj.fetch("duration", 0)
          snapshot.commit_sha = obj.fetch("commit_sha", nil)
          snapshot.commit_timestamp = obj.fetch("commit_timestamp", nil)
          snapshot.files = obj.fetch("files", 0)
          snapshot.rbi_files = obj.fetch("rbi_files", 0)
          snapshot.modules = obj.fetch("modules", 0)
          snapshot.classes = obj.fetch("classes", 0)
          snapshot.singleton_classes = obj.fetch("singleton_classes", 0)
          snapshot.methods_with_sig = obj.fetch("methods_with_sig", 0)
          snapshot.methods_without_sig = obj.fetch("methods_without_sig", 0)
          snapshot.calls_typed = obj.fetch("calls_typed", 0)
          snapshot.calls_untyped = obj.fetch("calls_untyped", 0)
          snapshot.methods_with_sig_excluding_rbis = obj.fetch("methods_with_sig_excluding_rbis", 0)
          snapshot.methods_without_sig_excluding_rbis = obj.fetch("methods_without_sig_excluding_rbis", 0)

          sigils = obj.fetch("sigils", {})
          if sigils
            Snapshot::STRICTNESSES.each do |strictness|
              next unless sigils.key?(strictness)

              snapshot.sigils[strictness] = sigils[strictness]
            end
          end

          sigils_excluding_rbis = obj.fetch("sigils_excluding_rbis", {})
          if sigils_excluding_rbis
            Snapshot::STRICTNESSES.each do |strictness|
              next unless sigils_excluding_rbis.key?(strictness)

              snapshot.sigils_excluding_rbis[strictness] = sigils_excluding_rbis[strictness]
            end
          end

          snapshot
        end
      end
    end

    class SnapshotPrinter < Spoom::Printer
      #: (Snapshot snapshot) -> void
      def print_snapshot(snapshot)
        methods = snapshot.methods_with_sig + snapshot.methods_without_sig
        methods_excluding_rbis = snapshot.methods_with_sig_excluding_rbis + snapshot.methods_without_sig_excluding_rbis
        calls = snapshot.calls_typed + snapshot.calls_untyped

        if snapshot.version_static || snapshot.version_runtime
          printl("Sorbet static: #{snapshot.version_static}") if snapshot.version_static
          printl("Sorbet runtime: #{snapshot.version_runtime}") if snapshot.version_runtime
          printn
        end
        printl("Content:")
        indent
        printl("files: #{snapshot.files}")
        printl("files excluding rbis: #{snapshot.files - snapshot.rbi_files}")
        printl("modules: #{snapshot.modules}")
        printl("classes: #{snapshot.classes - snapshot.singleton_classes}")
        printl("methods: #{methods}")
        printl("methods excluding rbis: #{methods_excluding_rbis}")
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
        printl("Methods excluding RBIs")
        methods_excluding_rbis_map = {
          "with signature" => snapshot.methods_with_sig_excluding_rbis,
          "without signature" => snapshot.methods_without_sig_excluding_rbis,
        }
        print_map(methods_excluding_rbis_map, methods_excluding_rbis)
        printn
        printl("Calls:")
        calls_map = {
          "typed" => snapshot.calls_typed,
          "untyped" => snapshot.calls_untyped,
        }
        print_map(calls_map, calls)
      end

      private

      #: (Hash[String, Integer] hash, Integer total) -> void
      def print_map(hash, total)
        indent
        hash.each do |key, value|
          next if value <= 0

          printl("#{key}: #{value}#{percent(value, total)}")
        end
        dedent
      end

      #: (Integer? value, Integer? total) -> String
      def percent(value, total)
        return "" if value.nil? || total.nil? || total == 0

        " (#{(value.to_f * 100.0 / total.to_f).round}%)"
      end
    end
  end
end
