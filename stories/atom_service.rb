require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/server'

steps_for(:atom_service_interation) do
  # Givens
  Given("existing feeds in the system") do 
    @feeds = Feed.find(:all)
  end
  
  Given("feed $id in the system") do |id|
    @feed = Feed.find(id)
  end
  
  Given("item $i of the feed") do |i|
    @item = @feed.feed_items[i.to_i - 1]
  end
  
  Given("a base url") do
    @base = 'http://localhost:4000'
  end
  
  # Whens
  When("I fetch the service document") do
    @service = Atom::Pub::Service.load_service(URI.parse("#{@base}/service"))
  end
  
  When("I fetch the feed for the first collection") do
    @fetched_feed = @service.workspaces.first.collections.first.feed
  end
  
  When("item $i of the feed") do |i|
    @item = @fetched_feed.entries[i.to_i - 1]
    @dbitem = @feed.feed_items.find(:all, :order => 'time desc')[i.to_i - 1]
  end
  
  # Thens
  Then("the document should have a workspace") do
    @service.should have(1).workspaces
  end
  
  Then("the workspace should have a title") do
    @service.workspaces.first.title.should_not be_nil
  end
  
  Then("the workspace should have a collection for each feed") do
    @service.workspaces.first.collections.size.should == @feeds.size
  end
  
  Then("the collections should have hrefs pointing to the feeds") do
    @feeds.each_with_index do |feed, index|
      @service.workspaces.first.collections[index].href.should == "#{@base}/feeds/#{feed.id}.atom"
    end
  end
  
  Then("the collections should have titles for each of the feeds") do
    @feeds.each_with_index do |feed, index|
      @service.workspaces.first.collections[index].title.should == feed.title
    end
  end
  
  Then("the feed contains the title") do
    @fetched_feed.title.should == @feed.title
  end
  
  Then("the feed contains the items") do
    @fetched_feed.entries.size.should == @feed.feed_items.size
  end
  
  Then("the feed self link points to self") do
    @fetched_feed.links.self.href.should == "#{@base}/feeds/#{@feed.id}.atom"
  end
  
  Then("the feed alternate link points to source html") do
    @fetched_feed.links.alternate.href.should == @feed.link
  end
  
  Then("the $link link matches $link") do |link1_rel, link2_rel|
    link2 = @fetched_feed.links.detect {|link| link.rel == link2_rel }
    link2.should_not be_nil
    @fetched_feed.links.detect {|link| link.rel == link1_rel}.should == link2
  end
  
  Then("the $link link is missing") do |link_rel|
    @fetched_feed.links.detect{|l| l.rel == link_rel}.should be_nil
  end
  
  Then("the id fragment matches the feed id") do
    URI.parse(@fetched_feed.id).fragment.to_i.should == @feed.id
  end
  
  Then("the item matches item $i of the feed") do |i|    
    @item.title.should == @dbitem.title
    @item.updated.should == @dbitem.time
    @item.alternate.href.should == @dbitem.link
    URI.parse(@item.id).fragment.to_i.should == @dbitem.id
    @item.content.should == @dbitem.content.encoded_content
  end
  
  Then("the id fragment matches the item id") do
    URI.parse(@item.id).fragment.to_i.should == @dbitem.id
  end
  
  Then("the item's spider link points to the spider URL for the item") do
    @item.links.detect {|l| l.rel == 'http://peerworks.org/rel/spider' }.href.should == "#{@base}/spider/item/#{@dbitem.id}"
  end
end

with_steps_for(:atom_service_interation) do
  run_local_story "atom_service"
end