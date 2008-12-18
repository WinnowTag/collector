# Sets up the Rails environment for Cucumber
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + '/../../config/environment')
require 'cucumber/rails/world'
Cucumber::Rails.use_transactional_fixtures

# Comment out the next line if you're not using RSpec's matchers (should / should_not) in your steps.
require 'cucumber/rails/rspec'

fork do
  [STDOUT,STDERR].each {|f| f.reopen '/dev/null', 'w' }
  exec('mongrel_rails start -e test -p 4000')
  sleep(5)
end
