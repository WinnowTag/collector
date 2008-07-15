# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

describe User do  
  fixtures :users, :feed_items
  
  it "should_create_user" do
    assert_difference User, :count do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  it "should_require_login" do
    assert_no_difference User, :count do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  it "should_require_password" do
    assert_no_difference User, :count do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  it "should_require_password_confirmation" do
    assert_no_difference User, :count do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  it "should_require_email" do
    assert_no_difference User, :count do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  it "should_reset_password" do
    users(:admin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:admin), User.authenticate('admin', 'new password')
  end

  it "should_not_rehash_password" do
    users(:admin).update_attributes(:login => 'admin2')
    assert_equal users(:admin), User.authenticate('admin2', 'test')
  end

  it "should_authenticate_user" do
    assert_equal users(:admin), User.authenticate('admin', 'test')
  end

  it "should_set_remember_token" do
    users(:admin).remember_me
    assert_not_nil users(:admin).remember_token
    assert_not_nil users(:admin).remember_token_expires_at
  end

  it "should_unset_remember_token" do
    users(:admin).remember_me
    assert_not_nil users(:admin).remember_token
    users(:admin).forget_me
    assert_nil users(:admin).remember_token
  end
    
  it "timezone_should_not_be_nil" do
    assert_invalid create_user(:time_zone => nil)
  end

protected
  def create_user(options = {})
    User.create({ :login => 'quire', 
                  :email => 'quire@example.com', 
                  :password => 'quire', 
                  :firstname => 'Qu', 
                  :lastname => 'Ire',
                  :password_confirmation => 'quire' }.merge(options))
  end
end
