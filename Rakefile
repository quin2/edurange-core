require 'bundler/gem_tasks'
require 'rake/testtask'
require 'semantic_logger'

desc 'Run core tests'
Rake::TestTask.new do |t|
  t.name = "test:core"
  t.test_files = FileList['test/core/**/*_test.rb']
end

desc 'Run provider integration tests'
Rake::TestTask.new do |t|
  t.name = "test:providers"
  t.test_files = FileList['test/providers/**/*_test.rb']
end

#task default: 'test:core'

