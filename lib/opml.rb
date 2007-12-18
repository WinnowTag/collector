# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

require 'xml/libxml'

class Opml
  def self.parse(io)
    parser = XML::Parser.new
    
    case io
    when IO     then parser.io = io
    when String then parser.string = io
    else
      raise ArgumentError, "Dont know how to parse a #{io.class.name}"
    end
    
    new(parser.parse)
  end
  
  def initialize(document)
    @document = document
  end
  
  def feeds
    @document.find("/opml/body/outline[@xmlUrl]").map do |e|
      Feed.new(e)
    end
  end
  
  def inspect
    "<OPML>"
  end
  
  class Feed
    def initialize(element)
      @element = element
    end
    
    [:title, :xmlUrl].each do |m|
      define_method(m) do
        @element[m.to_s]
      end
    end    
  end
end
