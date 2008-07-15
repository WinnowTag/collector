# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class Protector < ActiveRecord::Base
  validates_uniqueness_of :name
  has_many :protected_items, :dependent => :delete_all
end
