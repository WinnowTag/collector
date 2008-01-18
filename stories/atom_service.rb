require File.dirname(__FILE__) + '/helper'
require File.dirname(__FILE__) + '/server'

Story "Atom Client Access", %{
  As another system
  I want to be able to access feeds and items using atom
  So that I can cache feeds and items in my own format
} do
  
  Scenario "Accessing the service description" do
    Given "existing feeds in the system", 0 do 
      @feeds = Feed.find(:all)
    end
    
    And  "a base url" do
      @base = 'http://localhost:4000'
    end
    
    When "I fetch the service document" do
      @service = Atom::Pub::Service.load_service(URI.parse("#{@base}/service"))
    end
    
    Then "the document should have a workspace" do
      @service.should have(1).workspaces
    end
    
    And  "the workspace should have a title" do
      @service.workspaces.first.title.should_not be_nil
    end
    
    And  "the workspace should have a collection for each feed" do
      @service.workspaces.first.collections.size.should == @feeds.size
    end
    
    And  "the collections should have hrefs pointing to the feeds" do
      @feeds.each_with_index do |feed, index|
        @service.workspaces.first.collections[index].href.should == "#{@base}/feeds/#{feed.id}.atom"
      end
    end
    
    And  "the collections should have titles for each of the feeds" do
      @feeds.each_with_index do |feed, index|
        @service.workspaces.first.collections[index].title.should == feed.title
      end
    end
  end
  
  Scenario "Accessing a feed" do
    Given "existing feeds in the system"
    And "a base url"
    
    When "I fetch the service document"
    And  "fetch the feed for the first collection"
    
    Then "the feed contains the items"
    And  "the $link matches self", :first
    And  "the $link matches self", :last
    And  "the $link is missing", :prev
    And  "the $link is missing", :next
    And  "the id fragment matches the system id"
  end
  
  Scenario "Accessing an item for a feed" do
    Given "existing feeds in the system"
    And "a base url"
    And "the first item of the first feed"
    
    When "I fetch the service document"
    And "fetch the feed for the first collection"
    
    Then "then the first item matches the first item of the first feed"
    And  "the item's alternate link points to the atom representation for the item"
    And  "the item's spider link points to the spider URL for the item"
    And  "the id fragment matches the system id"
  end
end