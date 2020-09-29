# typed: strict
# frozen_string_literal: true

module Spoom
  class Snapshot < Hash
    extend T::Sig
    extend T::Generic

    K = type_member(fixed: String)
    V = type_member(fixed: T.untyped)
    Elem = type_member(fixed: T.untyped)

    sig { params(path: String).returns(Snapshot) }
    def self.snapshot(path: '.')
      snapshot = Snapshot.new
      metrics = Spoom::Sorbet.srb_metrics(path: path, capture_err: false)
      return snapshot unless metrics

      snapshot["user_time"] = metrics["run.utilization.user_time.us"]
      snapshot["system_time"] = metrics["run.utilization.system_time.us"]
      snapshot["files"] = metrics["types.input.files"]
      snapshot["modules"] = metrics["types.input.modules.total"]
      snapshot["classes"] = metrics["types.input.classes.total"]
      snapshot["methods"] = metrics["types.input.methods.total"]
      snapshot["signatures"] = metrics["types.sig.count"]
      snapshot["calls"] = metrics["types.input.sends.total"]
      snapshot["calls_typed"] = metrics["types.input.sends.typed"]

      sigils = {}
      sigils["ignore"] = metrics["types.input.files.sigil.ignore"]
      sigils["false"] = metrics["types.input.files.sigil.false"]
      sigils["true"] = metrics["types.input.files.sigil.true"]
      sigils["strict"] = metrics["types.input.files.sigil.strict"]
      sigils["strong"] = metrics["types.input.files.sigil.strong"]
      sigils["stdlib"] = metrics["types.input.files.sigil.stdlib"]
      snapshot["sigils"] = sigils

      snapshot
    end

    sig { params(out: T.any(IO, StringIO), colors: T::Boolean, indent_level: Integer).void }
    def print(out: $stdout, colors: true, indent_level: 0)
      printer = SnapshotPrinter.new(out: out, colors: colors, indent_level: indent_level)
      printer.print_snapshot(self)
    end

    sig { returns(T::Hash[String, T.nilable(Integer)]) }
    def files_by_strictness
      Spoom::Sorbet::Sigils::VALID_STRICTNESS.each_with_object({}) do |sigil, map|
        map[sigil] = self["sigils"][sigil]
      end
    end
  end

  class SnapshotPrinter < Spoom::Printer
    extend T::Sig

    sig { params(snapshot: Snapshot).void }
    def print_snapshot(snapshot)
      printl("Sigils:")
      indent
      printl("files: #{snapshot['files']}")
      snapshot.files_by_strictness.each do |sigil, value|
        next unless value && value > 0
        printl("#{sigil}: #{value}#{percent(value, snapshot['files'])}")
      end
      dedent
      printn
      printl("Classes & Modules:")
      indent
      printl("classes: #{snapshot['classes']} (including singleton classes)")
      printl("modules: #{snapshot['modules']}")
      dedent
      printn
      printl("Methods:")
      indent
      printl("methods: #{snapshot['methods']}")
      printl("signatures: #{snapshot['signatures']}#{percent(snapshot['signatures'], snapshot['methods'])}")
      dedent
      printn
      printl("Sends:")
      indent
      printl("sends: #{snapshot['calls']}")
      printl("typed: #{snapshot['calls_typed']}#{percent(snapshot['calls_typed'], snapshot['calls'])}")
      dedent
    end

    private

    sig { params(value: T.nilable(Integer), total: T.nilable(Integer)).returns(String) }
    def percent(value, total)
      return "" if value.nil? || total.nil? || total == 0
      " (#{value * 100 / total}%)"
    end
  end
end
