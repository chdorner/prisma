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
  gem.name = 'prisma'
  gem.homepage = 'https://github.com/chdorner/prisma'
  gem.license = 'MIT'
  gem.summary = %Q{Simple request stats collector for Rails applications}
  gem.email = 'christof@chdorner.me'
  gem.authors = ['Christof Dorner']
  gem.files  = Dir.glob('lib/**/*')
  gem.files += Dir.glob('bin/**/*')
  gem.executables = ['prisma-web']
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.ruby_opts = '-w'
  spec.pattern = FileList['spec/**/*_spec.rb']
end

task default: :spec

require 'yard'
YARD::Rake::YardocTask.new

Rake::Task['console'].clear
task :console do
  sh "irb -I lib -r 'prisma'"
end

task :seed do
  require 'prisma'
  Prisma.redis.keys.each { |key| Prisma.redis.del key }

  GROUP_NAMES = [:counter_1, :counter_2, :bitmap_3, :bitmap_4]

  Prisma.setup do |config|
    GROUP_NAMES.each_with_index do |group_name, index|
      type = index < 2 ? :counter : :bitmap
      config.group(group_name, :type => type, :description => "Description of #{group_name}") { 1 }
    end
  end

  GROUP_NAMES.each_with_index do |group_name, group_index|
    puts "Seeding #{group_name}..."
    365.times do |n|
      key = "#{group_name}:#{(Date.today - n).strftime('%Y:%m:%d')}"

      count = rand(1000)
      count.times do |user_id|
        if group_index < 2
          Prisma.redis.incr key
        else
          Prisma.redis.setbit "#{Prisma.redis_namespace}:#{key}", user_id, 1
        end
      end
    end
  end
end

