# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

class UserTest < Test::Unit::TestCase  
  fixtures :users, :feed_items
  
  def test_should_create_user
    assert_difference User, :count do
      user = create_user
      assert !user.new_record?, "#{user.errors.full_messages.to_sentence}"
    end
  end

  def test_should_require_login
    assert_no_difference User, :count do
      u = create_user(:login => nil)
      assert u.errors.on(:login)
    end
  end

  def test_should_require_password
    assert_no_difference User, :count do
      u = create_user(:password => nil)
      assert u.errors.on(:password)
    end
  end

  def test_should_require_password_confirmation
    assert_no_difference User, :count do
      u = create_user(:password_confirmation => nil)
      assert u.errors.on(:password_confirmation)
    end
  end

  def test_should_require_email
    assert_no_difference User, :count do
      u = create_user(:email => nil)
      assert u.errors.on(:email)
    end
  end

  def test_should_reset_password
    users(:admin).update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert_equal users(:admin), User.authenticate('admin', 'new password')
  end

  def test_should_not_rehash_password
    users(:admin).update_attributes(:login => 'admin2')
    assert_equal users(:admin), User.authenticate('admin2', 'test')
  end

  def test_should_authenticate_user
    assert_equal users(:admin), User.authenticate('admin', 'test')
  end

  def test_should_set_remember_token
    users(:admin).remember_me
    assert_not_nil users(:admin).remember_token
    assert_not_nil users(:admin).remember_token_expires_at
  end

  def test_should_unset_remember_token
    users(:admin).remember_me
    assert_not_nil users(:admin).remember_token
    users(:admin).forget_me
    assert_nil users(:admin).remember_token
  end
    
  def test_timezone_should_not_be_nil
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
