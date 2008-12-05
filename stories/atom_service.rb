# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/server'

require 'atom'
require 'atom/pub'

steps_for(:atom_service_interation) do
  # Givens
  Given("existing feeds in the system") do 
    @feeds = Feed.find(:all, :conditions => 'duplicate_id is null')
  end
  
  Given("feed $id in the system") do |id|
    @test_object = Feed.find(id)
  end
  
  Given("item $i of the feed") do |i|
    @test_object = @test_object.feed_items.find(:all, :order => 'item_updated desc')[i.to_i - 1]
  end
  
  Given("a base url") do
    @base = 'http://localhost:4000'
  end
     
  # Whens
  When("I fetch the service document") do
    @service = Atom::Pub::Service.load_service(URI.parse("#{@base}/service"),
                                  :hmac_access_id => 'winnow_id', :hmac_secret_key => 'winnow_secret')
  end
  
  When("I fetch the feed for the first collection") do
    @atom = Atom::Feed.load_feed(URI.parse(@service.workspaces.first.collections.first.href),
                                 :hmac_access_id => 'winnow_id', :hmac_secret_key => 'winnow_secret')
  end
  
  When("item $i of the feed") do |i|
    @atom = @atom.entries[i.to_i - 1]
  end
  
  # Thens
  Then("the document should have a workspace") do
    @service.should have(1).workspaces
  end
  
  Then("the workspace should have a title") do
    @service.workspaces.first.title.should_not be_nil
  end
  
  Then("the workspace should have a collection for each feed") do
    @service.workspaces.first.should have(@feeds.size).collections
  end
  
  Then("the collections should have titles for each of the feeds") do
    @feeds.each_with_index do |feed, index|
      @service.workspaces.first.collections[index].title.should == feed.title
    end
  end
  
  Then("it contains the title") do
    @atom.title.should == @test_object.title
  end
  
  Then("the feed contains the items") do
    @atom.should have(@test_object.feed_items.size).entries
  end
  
  Then("the id is a uuid urn") do |db|
    @atom.id.should match(/urn:uuid:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/)
  end
  
  Then("fetching self returns an $klass") do |klass|
    @atom.reload!(:hmac_access_id => 'winnow_id', :hmac_secret_key => 'winnow_secret').should be_an_instance_of(klass.constantize)
  end
end

with_steps_for(:atom_service_interation) do
  run_local_story "atom_service"
end