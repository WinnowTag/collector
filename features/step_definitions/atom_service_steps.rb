# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
Given("existing feeds in the system") do 
  Feed.delete_all
  @feeds = [Feed.create!(valid_feed_attributes), Feed.create!(valid_feed_attributes)]
end

Given("a feed in the system") do
  Feed.delete_all
  @test_object = Feed.create!(valid_feed_attributes)
end

Given("an item in the feed") do
  @test_object = @test_object.feed_items.create!(valid_feed_item_attributes)
end

When("I fetch the service document") do
  get "/service", {}, hmac_headers("winnow_id", "winnow_secret", :method => "GET", :path => "/service", "DATE" => "Wed, 07 Jan 2009 17:30:35 GMT")
  @service = Atom::Pub::Service.load_service(response.body)
end

When("I fetch the feed for the first collection") do
  path = URI.parse(@service.workspaces.first.collections.first.href).path
  get path, {}, hmac_headers("winnow_id", "winnow_secret", :method => "GET", :path => path, "DATE" => "Wed, 07 Jan 2009 17:30:35 GMT")
  @atom = Atom::Feed.load_feed(response.body)
end

When("I get the first feed item entry") do
  @atom = @atom.entries.first
end

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

Then("the feed contains the items") do
  @atom.should have(@test_object.feed_items.size).entries
end

Then("it contains the title") do
  @atom.title.should == @test_object.title
end

Then("the id is a uuid urn") do
  @atom.id.should match(/urn:uuid:[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}/)
end
