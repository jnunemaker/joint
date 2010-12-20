require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake/testtask'
Rake::TestTask.new do |test|
  test.libs      << 'lib' << 'test'
  test.pattern   = 'test/**/test_*.rb'
  test.ruby_opts = ['-rubygems']
  test.verbose   = true
end

task :default => :test