require "rake"

desc "install rbytes"
task :rbytes do
  sh %(gem install rbytes)
end

desc "Install rubocoping"
task rubo_coping: :rbytes do
  sh %(rbytes install https://railsbytes.com/script/V4YsLQ)
end

desc "ruby_setup"
task ruby_setup: :rubo_coping
