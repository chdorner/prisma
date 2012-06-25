# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  gem.name = 'simple_request_stats'
  gem.homepage = 'https://github.com/chdorner/simple_request_stats'
  gem.license = 'MIT'
  gem.summary = %Q{Simple request stats collector for Rails applications}
  gem.email = 'christof@chdorner.me'
  gem.authors = ['Christof Dorner']
  gem.files = Dir.glob('lib/**/*.rb')
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new

Rake::Task['console'].clear
task :console do
  sh "irb -I lib -r 'simple_requests_stats'"
end
