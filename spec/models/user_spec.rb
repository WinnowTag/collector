# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
    create_user(:time_zone => nil).should_not be_valid
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
