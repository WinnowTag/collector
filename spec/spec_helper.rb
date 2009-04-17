# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.

# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

require File.join(File.dirname(__FILE__), 'matchers')

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  config.include WinnowMatchers, :type => :code
  config.include AuthenticatedTestHelper

  config.before(:each, :behaviour_type => :controller) do
    @controller.instance_eval { flash.stub!(:sweep) }
  end

  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Example::Configuration and Spec::Runner

  def referer(referer)
    @request.env['HTTP_REFERER'] = referer
  end

  def login_as(user_id_or_fixture_name)
    @request.session[:user] = case user_id_or_fixture_name
      when Numeric; user_id_or_fixture_name
      when Symbol; users(user_id_or_fixture_name).id
    end
  end
  
  def current_user
    @controller.send(:current_user)
  end
  
  def valid_feed_item_attributes(attributes = {})
    unique_id = rand(10000)
    { :link => "http://#{unique_id}.example.com", 
      :unique_id => unique_id,
      :title => "Feed Item #{unique_id}",
      :item_updated => Time.now
    }.merge(attributes)
  end
  
  def valid_feed_attributes(attributes = {})
    unique_id = rand(1000)
    { :url => "http://#{unique_id}.example.com/index.xml",
      :link => "http://#{unique_id}.example.com",
      :title => "#{unique_id} Example",
      :feed_items_count => 0,
      :created_on => Time.now,
      :updated_on => Time.now,
      :collection_errors_count => 0
    }.merge(attributes)
  end
  
  def mock_response(klass, body, headers = {})
    response = klass.new(nil, nil, nil)
    response.stub!(:body).and_return(body)
    
    headers.each do |k, v|
      response.stub!(:[]).with(k).and_return(v)
    end
    
    response
  end
end
