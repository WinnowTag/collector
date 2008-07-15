# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + "/../spec_helper.rb"

describe SpidersController do
  fixtures :users
    
  before(:each) do
    login_as(:admin)
  end

  it "should GET the index" do
    get :index
  end
end

