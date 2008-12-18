# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
directory "tmp/imported_corpus"

Rake::Task[:default].prerequisites.clear

task :default do
  Rake::Task['spec'].invoke
  Rake::Task['features'].invoke
end

namespace :test do  
  desc 'Test the classifier.'
  task :classifier do
    sh "cd vendor/bayes && rake"
  end 
end


desc "Task for CruiseControl.rb"
task :cruise do
  ENV['RAILS_ENV'] = RAILS_ENV = 'test'

  Rake::Task['db:migrate'].invoke
  Rake::Task['db:test:prepare'].invoke
  Rake::Task['rcov_for_cc'].invoke
end
