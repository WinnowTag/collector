# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe FeedItemsController do

  #Delete these examples and add some real ones
  it "should use FeedItemsController" do
    controller.should be_an_instance_of(FeedItemsController)
  end


  describe "GET 'show'" do
    before(:each) do
      @feed_item = mock_model(FeedItem)
      @feed_item.should_receive(:to_atom).with(:base => "http://test.host:80")
      FeedItem.should_receive(:find).with("1").and_return(@feed_item)
    end
    
    it "should be successful" do
      get 'show', :id => "1"
      response.should be_success
    end
    
    it "should return atom" do
      get 'show', :id => "1"
      response.content_type.should == 'application/atom+xml'
    end
  end
end
