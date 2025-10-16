# typed: true
# frozen_string_literal: true

def time_it(&block)
  start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  res = yield
  end_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  puts "Time taken: #{end_time - start_time} seconds"
  res
end

def list_files(path)
  puts "# Listing files...\n\n"

  Dir.glob(File.join(File.absolute_path(path), "**/*.rb"))
end
