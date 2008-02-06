# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class Taggable
  def self.find(corpus)
    Dir.glob(File.join(corpus, '*.html')).map do |taggable_file|
      if taggable_file =~ /^.*?(\d+).html/
        Taggable.new(taggable_file, $1)
      end
    end
  end
  
  attr_reader :taggable_id
  def initialize(file, taggable_id)
    @file, @taggable_id = file, taggable_id.to_i
  end
  
  def content
    File.read(@file)
  end
  
  def <=>(other)
    self.taggable_id <=> other.taggable_id
  end
end