require 'bundler/gem_tasks'
require 'rake/testtask'
require 'semantic_logger'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/*_test.rb']
end
desc 'Run tests'

task default: :test

