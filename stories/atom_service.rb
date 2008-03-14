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
    @test_object = @test_object.feed_items.find(:all, :order => 'time desc')[i.to_i - 1]
  end
  
  Given("a base url") do
    @base = 'http://localhost:4000'
  end
  
  # Whens
  When("I fetch the service document") do
    @service = Atom::Pub::Service.load_service(URI.parse("#{@base}/service"))
  end
  
  When("I fetch the feed for the first collection") do
    @atom = @service.workspaces.first.collections.first.feed
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
  
  Then("the id fragment matches the $db id") do |db|
    URI.parse(@atom.id).fragment.to_i.should == @test_object.id
  end
  
  Then("fetching self returns an $klass") do |klass|
    @atom.reload!.should be_an_instance_of(klass.constantize)
  end
end

with_steps_for(:atom_service_interation) do
  run_local_story "atom_service"
end