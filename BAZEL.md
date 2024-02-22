# Bazelizing an existing gem

## The Workspace file

We have to specify the Ruby version in the `WORKSPACE` file.
In the case of Shopify, we're trying to consolidate the Ruby version under one place only: the `.ruby-version` file.
See https://vault.shopify.io/gsd/projects/38447.

We can go around this by using the `host` value that will get the version currently installed in the host.

```starlark
rules_ruby_select_sdk(version = "host")
```

For the Bundle rule, we also need to account for the `spoom.gemspec` file:

```starlark
ruby_bundle(
    name = "bundle",
    srcs = ["//:spoom.gemspec", "//:lib/spoom/version.rb"],
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)
```

## Running the exe/spoom executable

Let's add the rule into the `BUILD.bazel` root file:

```starlark
ruby_binary(
    name = "spoom",
    main = "exe/spoom",
    srcs = glob(["exe/spoom", "lib/**/*.rb"]),
    deps = [
        "@bundle//:gems"
    ],
)
```

For now we'll depend on `@bundle//:gems` to get all the gems from the bundle installed.

```shell
$ bazel run spoom

/private/var/tmp/_bazel_at/adff73041cfea0a4370aff39a1980896/execroot/_main/bazel-out/darwin_arm64-fastbuild/bin/spoom:79:in `runfiles_envvar': undefined method `exists?' for File:Class (NoMethodError)

  if File.exists?(manifest)
         ^^^^^^^^
Did you mean?  exist?
	from /private/var/tmp/_bazel_at/adff73041cfea0a4370aff39a1980896/execroot/_main/bazel-out/darwin_arm64-fastbuild/bin/spoom:119:in `main'
	from /private/var/tmp/_bazel_at/adff73041cfea0a4370aff39a1980896/execroot/_main/bazel-out/darwin_arm64-fastbuild/bin/spoom:155:in `<main>'
```

It seems the Ruby wrapper is using the deprecated method `File.exists`. This method has been removed in Ruby 3.2.2. We'll need to update this wrapper (see: https://github.com/bazelruby/rules_ruby/blob/master/ruby/private/binary_wrapper.tpl#L85). For now I'll just used Ruby 3.1.4.

```bash
chruby 3.1.4
$ bazel run spoom

<internal:/opt/rubies/3.1.4/lib/ruby/3.1.0/rubygems/core_ext/kernel_require.rb>:85:in `require': cannot load such file -- spoom/file_collector (LoadError)
```

Let's add `lib/` as a dependency:

```starlark
ruby_library(
    name = "lib",
    srcs = glob(["lib/**/*.rb"]),
    includes = ["lib"],
)

ruby_binary(
    name = "spoom",
    main = "exe/spoom",
    srcs = [
        "exe/spoom",
        "Gemfile",
        "Gemfile.lock",
    ],
    deps = [
        ":lib",
        "@bundle//:gems"
    ],
)
```

```bash
chruby 3.1.4
$ bazel run spoom

/opt/rubies/3.1.1/lib/ruby/3.1.0/rubygems/dependency.rb:311:in `to_specs': Could not find 'sorbet-static' (>= 0) among 70 total gem(s) (Gem::MissingSpecError)
```

Problem with `Gem::Specification.find_by_name`. It can't find the specification from the bundle?

Looking at the generated environement, it seems the runtime dependency to the native extension only installed the bin stub but not the gem definition.

The problem seems to be the wrapper used to run the bin that doesn't play nice with bundle API. We'll need to update the wrapper to set the correct bundle environment.

Final note about execution: the behavior change in Bundler is quite painful.

Some problems with `require_relative` that are resolved using
the current Ruby file path from `lib/` rather than the container?
