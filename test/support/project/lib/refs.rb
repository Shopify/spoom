# typed: true
# frozen_string_literal: true

ref = ARGV.first
ref = ref.downcase
ref.sub!("name", "Alex")
puts ref
