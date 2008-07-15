# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
ENV["RAILS_ENV"] = "test"
require 'test/unit'
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'test_help'

class Test::Unit::TestCase
  include AuthenticatedTestHelper
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  def assert_valid(o, msg = "The object should be valid")
    assert o.valid?, msg + ': ' + o.errors.to_s
  end
  
  def assert_invalid(o, msg = "The object should be invalid")
    assert !o.valid?, msg
  end
  
  def self.requires_post(action, options = {})
    self.send(:define_method, "test_#{action}_requires_post".to_sym) do
      if options[:user]
        login_as(options[:user]) 
      else
        login_as(:quentin)
      end
      get action, options[:params], options[:session]
      assert_response :redirect
      assert_redirected_to options[:redirect_to] if options[:redirect_to]
      assert_equal "Action can not be called with HTTP get", flash[:error]
    end
  end
  
  def assert_action_requires_post(action, options)    
    get action, options[:params], options[:session]
    assert_response :redirect
    assert_redirected_to options[:redirect_to] if options[:redirect_to]
    assert_equal "Action can not be called with HTTP get", flash[:error]
    yield(:get) if block_given?
    
    post action, options[:params], options[:session]
    assert_response :redirect
    assert_redirected_to options[:redirect_to] if options[:redirect_to]
    yield(:post) if block_given?
  end
  
  # These helpers were inspired by the authorize plugin Integration Tests
  # See: http://svn.writertopia.com/svn/testapps/object_roles_test/test/integration/stories_test.rb
  def cannot_access(user, method, action, args = {})
    login_as(user)
    self.send(method, action, args)
    assert_response :redirect
    assert_redirected_to "/account/login"
  end
  
  def referer(referer)
    @request.env['HTTP_REFERER'] = referer
  end
  
  def assert_include(o, arr, msg = "#{o.to_s} not found in #{arr.inspect}")
    assert arr.include?(o), msg
  end
  
  def assert_not_include(o, arr, msg = "#{o.to_s} not found in #{arr.inspect}")
    assert !arr.include?(o), msg
  end
end
