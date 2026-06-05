# typed: strict
# frozen_string_literal: true

source "https://rubygems.org"

gemspec

# TODO: Switch back to a released version once https://github.com/Shopify/rbi/pull/604 is released.
gem "rbi", github: "Shopify/rbi", ref: "f065ff970d20540c7ce865901b01db24308f7f3a"

gem "minitest"
gem "minitest-mock"

group :development do
  gem "debug"
  gem "rubocop-shopify", require: false
  gem "rubocop-sorbet", require: false
  gem "rubocop-minitest", require: false
  gem "tapioca", require: false
end
