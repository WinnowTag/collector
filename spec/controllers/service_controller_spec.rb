# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe ServiceController do
  before(:each) do
    @feeds = mock('feeds')
    Feed.stub!(:find).with(:all, :conditions => ['duplicate_id is null']).and_return(@feeds)
  end
  
  it "should assign the feeds to @feeds" do
    get 'index'
    response.should be_success
    assigns[:feeds].should == @feeds
  end
  
  it "should respond with an atom content type" do
    get 'index'
    response.content_type.should == 'application/atom+xml'
  end  
end