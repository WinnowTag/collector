# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

class Tagging
  def self.load(corpus, file)
    File.readlines(File.join(corpus, file)).map do |line|
      if line =~ /^(.+),(\d+),(-?[\d\.e-]+)$/
        Tagging.new($1, $2, $3)
      else
        puts "Skipping: #{line}"
      end
    end.compact
  end
  
  def self.load_for_tagger(corpus, tagger)
    self.load(corpus, "#{tagger}-taggings.csv")
  end
  
  attr_reader :tag, :taggable_id, :strength
  def initialize(tag, taggable_id, strength)
    @tag, @taggable_id, @strength = tag, taggable_id.to_i, strength.to_f
  end
end