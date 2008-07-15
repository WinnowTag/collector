# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

directory "tmp/imported_corpus"

Rake::Task[:default].prerequisites.clear

task :default do
  Rake::Task['spec'].invoke
  Rake::Task['test:stories'].invoke
end

namespace :test do  
  desc "Run stories"
  task :stories do
    system("ruby stories/all.rb")
  end
  
  desc 'Test the classifier.'
  task :classifier do
    sh "cd vendor/bayes && rake"
  end 
end

require File.dirname(__FILE__) + '/../../vendor/plugins/rspec/lib/spec/rake/spectask'

desc "Run all examples with RCov"
Spec::Rake::SpecTask.new('rcov_for_cc') do |t|
  t.spec_files = FileList['spec/controllers/**/*.rb', 'spec/helpers/*.rb', 'spec/models/*.rb', 'spec/views/*.rb']
  t.rcov = true
  t.rcov_opts = ['--exclude', 'spec']
  t.rcov_dir = ENV['CC_BUILD_ARTIFACTS']
end

desc "Task for CruiseControl.rb"
task :cruise do
  ENV['RAILS_ENV'] = RAILS_ENV = 'test'

  Rake::Task['db:migrate'].invoke
  Rake::Task['db:test:prepare'].invoke
  Rake::Task['rcov_for_cc'].invoke
end
