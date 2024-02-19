# typed: true
# frozen_string_literal: true

require "test_helper"

module Spoom
  class Context
    class SorbetTest < Minitest::Test
      def test_context_write_sorbet_config!
        context = Context.mktmp!

        assert_raises(Errno::ENOENT) do
          context.read_sorbet_config
        end

        context.write_sorbet_config!(".")
        assert_equal(".", context.read_sorbet_config)

        context.destroy!
      end

      def test_context_run_srb_from_bundle
        context = Context.mktmp!

        context.write!("a.rb", <<~RB)
          # typed: true

          foo(42)
        RB

        res = context.srb("tc")
        refute(res.status)

        context.write_gemfile!(<<~GEMFILE)
          source "https://rubygems.org"

          gem "sorbet"
        GEMFILE
        context.bundle("config set --local path $GEM_HOME")
        context.bundle_install!

        res = context.srb("tc")
        refute(res.status)

        context.write_sorbet_config!(".")
        res = context.srb("tc")
        assert_equal(<<~ERR, res.err)
          a.rb:3: Method `foo` does not exist on `T.class_of(<root>)` https://srb.help/7003
               3 |foo(42)
                  ^^^
          Errors: 1
        ERR
        refute(res.status)

        context.write!("b.rb", <<~RB)
          def foo(value); end
        RB

        res = context.srb("tc")
        assert(res.status)

        context.destroy!
      end

      def test_context_run_srb_from_path
        context = Context.mktmp!
        context.write_gemfile!(<<~GEMFILE)
          source "https://rubygems.org"

          gem "sorbet"
        GEMFILE
        context.bundle_install!

        result = context.srb(
          "-h",
          capture_err: true,
          sorbet_bin: Spoom::Sorbet::BIN_PATH,
        )
        assert_equal(<<~OUT, result.err)
          Typechecker for Ruby
          Usage:
            sorbet [OPTION...] <path 1> <path 2> ...

            -e string      Parse an inline ruby string (default: "")
            -q, --quiet    Silence all non-critical errors
            -v, --verbose  Verbosity level [0-3]
            -h             Show short help
                --help     Show long help
                --version  Show version

        OUT
        assert(result.status)
        assert_equal(0, result.exit_code)

        context.destroy!
      end

      def test_context_run_srb_raises_when_killed
        context = Context.mktmp!

        mock_result = ExecResult.new(
          out: "out",
          err: "err",
          status: false,
          exit_code: Spoom::Sorbet::KILLED_CODE,
        )

        context.stub(:exec, mock_result) do
          assert_raises(Spoom::Sorbet::Error::Killed, "Sorbet was killed.") do
            context.srb("-e foo")
          end
        end

        context.destroy!
      end

      def test_context_run_srb_raises_on_sefault
        context = Context.mktmp!

        mock_result = ExecResult.new(
          out: "out",
          err: "err",
          status: false,
          exit_code: Spoom::Sorbet::SEGFAULT_CODE,
        )

        context.stub(:exec, mock_result) do
          assert_raises(Spoom::Sorbet::Error::Segfault, "Sorbet segfaulted.") do
            context.srb("-e foo")
          end
        end

        context.destroy!
      end

      def test_context_run_srb_tc_from_path
        context = Context.mktmp!

        res = context.srb_tc("-e ''", sorbet_bin: Spoom::Sorbet::BIN_PATH)
        assert_equal(<<~OUT, res.err)
          No errors! Great job.
        OUT
        assert(res.status)
        assert_equal(0, res.exit_code)

        context.destroy!
      end

      def test_context_run_srb_metrics_from_path
        context = Context.mktmp!

        res = context.srb_metrics("-e ''", sorbet_bin: Spoom::Sorbet::BIN_PATH)
        assert_instance_of(Hash, res)
        refute_empty(res)

        context.destroy!
      end

      def test_context_srb_version_return_nil_if_srb_not_installed
        context = Context.mktmp!
        context.write_gemfile!("")

        assert_nil(context.srb_version)

        context.destroy!
      end

      def test_context_srb_version_return_version_string
        context = Context.mktmp!
        context.write_gemfile!(<<~GEMFILE)
          source "https://rubygems.org"

          gem "sorbet"
        GEMFILE
        context.bundle_install!

        refute_nil(context.srb_version)

        context.destroy!
      end

      def test_context_has_sorbet_config
        context = Context.mktmp!
        refute(context.has_sorbet_config?)

        context.write_sorbet_config!(".")
        assert(context.has_sorbet_config?)

        context.destroy!
      end

      def test_context_file_strictness
        context = Context.mktmp!

        assert_nil(context.read_file_strictness("a.rb"))

        context.write!("a.rb", "")
        assert_nil(context.read_file_strictness("a.rb"))

        context.write!("a.rb", "# typed: true\n")
        assert_equal("true", context.read_file_strictness("a.rb"))

        context.destroy!
      end

      def test_context_sorbet_intro_not_found
        context = Context.mktmp!
        context.git_init!
        context.git("config user.name 'John Doe'")
        context.git("config user.email 'john@doe.org'")

        assert_nil(context.sorbet_intro_commit)

        context.destroy!
      end

      def test_context_sorbet_intro_found
        intro_time = Time.parse("1987-02-05 09:00:00 +0000")
        context = Context.mktmp!
        context.git_init!
        context.git("config user.name 'John Doe'")
        context.git("config user.email 'john@doe.org'")
        context.write!("sorbet/config")
        context.git_commit!(time: intro_time)

        commit = context.sorbet_intro_commit
        assert_match(/\A[a-z0-9]+\z/, commit&.sha)
        assert_equal(intro_time, commit&.time)

        context.destroy!
      end

      def test_context_sorbet_removal_not_found
        context = Context.mktmp!
        context.git_init!
        context.git("config user.name 'John Doe'")
        context.git("config user.email 'john@doe.org'")

        assert_nil(context.sorbet_removal_commit)

        context.destroy!
      end

      def test_context_sorbet_removal_found
        intro_time = Time.parse("1987-02-05 09:00:00 +0000")
        removal_time = Time.parse("1987-02-05 21:00:00 +0000")
        context = Context.mktmp!
        context.git_init!
        context.git("config user.name 'John Doe'")
        context.git("config user.email 'john@doe.org'")
        context.write!("sorbet/config")
        context.git_commit!(time: intro_time)
        context.remove!("sorbet/config")
        context.git_commit!(time: removal_time)

        commit = context.sorbet_removal_commit
        assert_match(/\A[a-z0-9]+\z/, commit&.sha)
        assert_equal(removal_time, commit&.time)

        context.destroy!
      end

      def test_context_srb_files_with_default_extensions
        context = Context.mktmp!

        context.write_sorbet_config!(".")

        context.write!("a.rb", "")
        context.write!("b/c.rb", "")
        context.write!("d/e/f.rbi", "")
        context.write!("g.rake", "")
        context.write!("h.js", "")
        context.write!("i", "")

        assert_equal(["a.rb", "b/c.rb", "d/e/f.rbi"], context.srb_files)

        context.destroy!
      end

      def test_context_srb_files_with_custom_extensions
        context = Context.mktmp!

        context.write_sorbet_config!(<<~CONFIG)
          .
          --allowed-extension=.rb
          --allowed-extension=.rbi
          --allowed-extension=.rake
        CONFIG

        context.write!("a.rb", "")
        context.write!("b/c.rb", "")
        context.write!("d/e/f.rbi", "")
        context.write!("g.rake", "")
        context.write!("h", "")

        assert_equal(["a.rb", "b/c.rb", "d/e/f.rbi", "g.rake"], context.srb_files)

        context.destroy!
      end

      def test_context_srb_files_with_custom_paths
        context = Context.mktmp!

        context.write_sorbet_config!(<<~CONFIG)
          b
          d
        CONFIG

        context.write!("a.rb", "")
        context.write!("b/c.rb", "")
        context.write!("d/e/f.rbi", "")
        context.write!("g.rake", "")
        context.write!("h", "")

        assert_equal(["b/c.rb", "d/e/f.rbi"], context.srb_files)

        context.destroy!
      end

      def test_context_srb_files_with_custom_ignore
        context = Context.mktmp!

        context.write_sorbet_config!(<<~CONFIG)
          .
          --ignore=foo
          --ignore=baz
        CONFIG

        context.write!("foo.rb", "")
        context.write!("foo/bar.rb", "")
        context.write!("bar/foo/baz.rb", "")
        context.write!("foo2/bar.rb", "")
        context.write!("baz", "")

        # From Sorbet docs on `--ignore`:
        # > Ignores input files that contain the given string in their paths (relative to the input path passed to
        # > Sorbet). Strings beginning with / match against the prefix of these relative paths; others are substring
        # > matches. Matches must be against whole folder and file names, so `foo` matches `/foo/bar.rb` and
        # > `/bar/foo/baz.rb` but not `/foo.rb` or `/foo2/bar.rb`.
        assert_equal(["foo.rb", "foo2/bar.rb"], context.srb_files)

        context.destroy!
      end

      def test_context_srb_files_with_custom_ignore_prefixed_with_slash
        context = Context.mktmp!

        context.write_sorbet_config!(<<~CONFIG)
          .
          --ignore=/config/routes.rb
          --ignore=/lib/generators/
        CONFIG

        context.write!("foo.rb", "")
        context.write!("config/routes.rb", "")
        context.write!("lib/generators/generator1.rb", "")
        context.write!("lib/generators/generator2.rb", "")
        context.write!("foo/lib/generators/generator.rb", "")

        assert_equal(["foo.rb", "foo/lib/generators/generator.rb"], context.srb_files)

        context.destroy!
      end

      def test_context_srb_files_with_custom_config
        context = Context.mktmp!

        context.write_sorbet_config!(".")

        context.write!("a.rb", "")
        context.write!("b/c.rb", "")
        context.write!("d/e/f.rbi", "")
        context.write!("g.rake", "")
        context.write!("h.js", "")
        context.write!("i", "")

        config = Spoom::Sorbet::Config.new
        config.paths = ["b", "d"]

        assert_equal(["b/c.rb", "d/e/f.rbi"], context.srb_files(with_config: config))

        context.destroy!
      end

      def test_context_srb_files_without_rbis
        context = Context.mktmp!

        context.write_sorbet_config!(".")

        context.write!("a.rb", "")
        context.write!("b.rbi", "")

        assert_equal(["a.rb"], context.srb_files(include_rbis: false))

        context.destroy!
      end

      def test_context_srb_files_with_strictness
        context = Context.mktmp!
        context.write_sorbet_config!(".")
        context.write!("false.rb", "# typed: false")
        context.write!("true.rb", "# typed: true")
        context.write!("nested/false.rb", "# typed: false")
        context.write!("nested/true.rb", "# typed: true")

        files = context.srb_files_with_strictness("false")
        assert_equal(["false.rb", "nested/false.rb"], files)

        context.destroy!
      end

      def test_context_srb_files_with_strictness_with_iso_content
        string_utf = <<~RB
          # typed: true

          puts "À coûté 10€"
        RB

        string_iso = string_utf.encode("ISO-8859-15")

        context = Context.mktmp!
        context.write_sorbet_config!(".")
        context.write!("file1.rb", string_utf)
        context.write!("file2.rb", string_iso)

        files = context.srb_files_with_strictness("true")
        assert_equal(["file1.rb", "file2.rb"], files)

        context.destroy!
      end
    end
  end
end
