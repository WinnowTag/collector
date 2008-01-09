#!/usr/bin/env ruby

# DWS- Extra comment line added by Don as test of dav write.

# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
# winnow_collect.rb
# Retrieves new feed distribution files and saves new items.

ENV['RAILS_ENV'] ||= 'production'
require File.join(File.dirname(__FILE__), '/config/environment')
Spider.logger = Logger.new(File.join(RAILS_ROOT, "log", "winnow_collect-spider.log"), 'daily')

Feed.collect_all
FeedItemContent.index_new_items
ActiveRecord::Base.connection.disconnect!