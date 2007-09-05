# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

directory "tmp/imported_corpus"
task :test => ['test:pw_plugins', 'test:classifier']

namespace :test do
  task :functionals => "tmp/imported_corpus"
  
  desc "Run rcov on current app"
  task :rcov do
    test_dir    = "#{RAILS_ROOT}/test"
    dirs        = [ "#{test_dir}/functional/*.rb",
                    "#{test_dir}/integration/*.rb",
                    "#{test_dir}/unit/*.rb",
                    "#{test_dir}/unit/helpers/*.rb",]

    output_dir = (ENV['CC_BUILD_ARTIFACTS'] or 'test')
    command = "rcov --rails -o #{output_dir}/coverage"

    dirs.each do |dir|
      command += " #{dir}" unless Dir[dir].empty?
    end
    sh command
  end
  
  desc 'Test the classifier.'
  task :classifier do
    sh "cd vendor/bayes && rake"
  end
  
  desc 'Test all custom plugins'
  task :pw_plugins do
    %w(winnow_feed).each do |plugin|
      cd "vendor/plugins/#{plugin}" do
        sh "rake"
      end
    end
  end
end

desc "Task for CruiseControl.rb"
task :cruise do
  ENV['RAILS_ENV'] = RAILS_ENV = 'test'

  [:'test:recent', :'test:units', :'test:functionals', :'test:integration'].each do |task|
    # Removes each of their db:test:prepare dependency
    Rake::Task[task].prerequisites.delete('db:test:prepare')
  end
  
  Rake::Task['db:test:prepare'].invoke
  Rake::Task['db:migrate'].invoke
  Rake::Task['test'].invoke
  Rake::Task['test:rcov'].invoke
end
