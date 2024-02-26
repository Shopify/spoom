workspace(name = "spoom")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

# git_repository(
#     name = "bazelruby_rules_ruby",
#     remote = "https://github.com/bazelruby/rules_ruby.git",
#     branch = "master"
# )

local_repository(
    name = "bazelruby_rules_ruby",
    path = "/Users/at/src/github.com/Morriar/rules_ruby",
)

load(
    "@bazelruby_rules_ruby//ruby:deps.bzl",
    "rules_ruby_dependencies",
    "rules_ruby_select_sdk",
)

rules_ruby_dependencies()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")
bazel_skylib_workspace()

rules_ruby_select_sdk(version = "host")

load(
    "@bazelruby_rules_ruby//ruby:defs.bzl",
    "ruby_bundle",
)

ruby_bundle(
    name = "bundle",
    srcs = ["//:spoom.gemspec", "//:lib/spoom/version.rb"],
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)
