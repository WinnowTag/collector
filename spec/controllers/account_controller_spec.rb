# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe AccountController do
  fixtures :users

  it "should_login_and_redirect" do
    post :login, :login => 'admin', :password => 'test'
    assert session[:user]
    assert_response :redirect
  end

  it "should_fail_login_and_not_redirect" do
    post :login, :login => 'admin', :password => 'bad password'
    assert_nil session[:user]
    assert_response :success
  end

  it "should_logout" do
    login_as :admin
    get :logout
    assert_nil session[:user]
    assert_response :redirect
  end

  it "should_remember_me" do
    post :login, :login => 'admin', :password => 'test', :remember_me => "1"
    assert_not_nil @response.cookies["auth_token"]
  end

  it "should_not_remember_me" do
    post :login, :login => 'admin', :password => 'test', :remember_me => "0"
    assert_nil @response.cookies["auth_token"]
  end
  
  it "should_delete_token_on_logout" do
    login_as :admin
    get :logout
    assert_equal @response.cookies["auth_token"], []
  end

  it "should_login_with_cookie" do
    users(:admin).remember_me
    @request.cookies["auth_token"] = cookie_for(:admin)
    get :edit, :id => users(:admin).login
    assert @controller.send(:logged_in?)
  end

  it "should_fail_cookie_login" do
    users(:admin).remember_me
    users(:admin).update_attribute :remember_token_expires_at, 5.minutes.ago.utc
    @request.cookies["auth_token"] = cookie_for(:admin)
    get :edit, :id => users(:admin).login
    assert !@controller.send(:logged_in?)
  end

  it "should_fail_cookie_login" do
    users(:admin).remember_me
    @request.cookies["auth_token"] = auth_token('invalid_auth_token')
    get :edit, :id => users(:admin).login
    assert !@controller.send(:logged_in?)
  end
 
  it "edit_can_only_change_some_values" do
    referer('')
    login_as(:admin)
    post :edit, :current_user => {:firstname => 'Someone', :lastname => 'Else', :email => 'someone@else.com', :login => 'evil'}
    u = User.find(users(:admin).id)
    assert_equal 'Someone', u.firstname
    assert_equal 'Else', u.lastname
    assert_equal 'someone@else.com', u.email
    assert_equal users(:admin).crypted_password, u.crypted_password
    assert_equal users(:admin).login, u.login
    assert_redirected_to ''
  end
  
  it "get_edit_returns_the_form" do
    login_as(:admin)
    get :edit
    assert_response :success
    assert_template 'edit'
  end
  
  it "edit_requires_login" do
    assert_requires_login do 
      get :edit
      post :edit
    end
  end
  
  it "should_allow_password_change" do
    referer("")
    post :login, :login => 'admin', :password => 'test'
    post :edit, :current_user => { :password => 'newpassword', :password_confirmation => 'newpassword' }
    assert_equal 'newpassword', assigns(:current_user).password
    assert_equal "Information updated", flash[:notice]
    assert_redirected_to ''
    post :logout
    assert_nil session[:user]
    post :login, :login => 'admin', :password => 'newpassword'
    assert session[:user] 
    assert_response :redirect
  end

  it "non_matching_passwords_should_not_change" do
    post :login, :login => 'admin', :password => 'test'
    assert session[:user]
    post :edit, :current_user => { :password => 'newpassword', :password_confirmation => 'test' }
    assert_not_equal 'newpassword', assigns(:current_user).password
    assert_equal "Password mismatch", flash[:notice]
  end

  it "login_updates_logged_in_at_time" do
    previous_login_time = User.find_by_login('admin').logged_in_at
    post :login, :login => 'admin', :password => 'test'
    assert_not_nil User.find_by_login('admin').logged_in_at
    assert_not_equal previous_login_time, User.find_by_login('admin').logged_in_at
  end
  
protected
  def auth_token(token)
    CGI::Cookie.new('name' => 'auth_token', 'value' => token)
  end
  
  def cookie_for(user)
    auth_token users(user).remember_token
  end
end
