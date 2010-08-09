require 'rubygems'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/joint/version', __FILE__)

Rake::TestTask.new do |test|
  test.libs      << 'lib' << 'test'
  test.pattern   = 'test/**/test_*.rb'
  test.ruby_opts = ['-rubygems']
  test.verbose   = true
end

task :default => :test

desc 'Builds the gem'
task :build do
  sh "gem build joint.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install joint-#{Joint::Version}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{Joint::Version}"
  sh "git push origin master"
  sh "git push origin v#{Joint::Version}"
  sh "gem push joint-#{Joint::Version}.gem"
end
