# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require File.dirname(__FILE__) + '/../spec_helper'

describe ApplicationHelper do
  describe '.unescape' do
    it "should return nil when it gets nil" do
      helper.unescape(nil).should be_nil
    end    
  end
end
