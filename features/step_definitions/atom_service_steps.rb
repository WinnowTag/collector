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
