# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/index.html.erb' do
  it "should escape titles in the confirm dialog for deletion" do
    assigns[:feeds] = [mock_model(Feed, valid_feed_attributes(:title => "quote&apos;s"))].paginate
    render '/feeds/index.html.erb'
    
    response.should have_tag("a[onclick*='confirm('Do you really want to delete quote\\'s?')']", true, response.body)
  end  
end