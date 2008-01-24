# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/helper'

steps_for(:feed_management) do
  Given('no feeds') do
    Feed.delete_all    
  end
  
  Given('$n item caches?') do |n|
    if n == "no"
    elsif n == "1"
      ItemCache.delete_all
      @item_cache = ItemCache.create!(:base_uri => 'http://example.org')
    end
  end
  
  Given('I am a logged in user') do
    post '/account/login', :login => 'admin', :password => 'test'
  end
  
  Given('the item cache expects a POST') do
    response = Net::HTTPSuccess.new(nil,nil,nil)
    response.should_receive(:body).and_return("")
    http = Object.new
    http.should_receive(:post)
    Net::HTTP.should_receive(:start).with('example.org', 80).and_yield(http)
  end
  
  When('I add the feed $url') do |url|
    post '/feeds', :feed => {:url => url}
  end
  
  Then('there is another feed in the system') do
    Feed.count.should == 1
  end  
end

with_steps_for(:feed_management) do
  run_local_story 'feed_management', :type => RailsStory
end
