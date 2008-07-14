# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/feeds/index.rhtml' do
  it "should escape titles in the confirm dialog for deletion" do
    assigns[:feeds] = [mock_model(Feed, valid_feed_attributes(:title => "quote&apos;s"))]
    render '/feeds/index.rhtml'
    
    response.should have_tag("a[onclick*='confirm('Do you really want to delete quote\\'s?')']", true, response.body)
  end  
end