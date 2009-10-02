$:.unshift(RAILS_ROOT + '/vendor/gems/cucumber-0.1.14/lib')
require 'cucumber/rake/task'

task :clear_cucumber do 
  rm_rf("cucumber")
  mkdir("cucumber")
end

Cucumber::Rake::Task.new(:features_for_ci) do |t|
  t.cucumber_opts = "--format html > cucumber/features.html"
end

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "--format pretty"
end
task :features => 'db:test:prepare'
task :features_for_ci => ['clear_cucumber']