# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class ItemCache < ActiveRecord::Base
  validates_presence_of :base_uri
  validates_uniqueness_of :base_uri
  validates_format_of :base_uri, :with => /^http:\/\/.*/, :message => 'must be a HTTP uri'
    
  def base_uri=(v)
    if v.respond_to?(:sub)
      # Trim any trailing slashes
      v = v.sub(/\/$/, '')
    end
    
    write_attribute(:base_uri, v)
  end
end
