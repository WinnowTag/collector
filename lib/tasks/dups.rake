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

namespace :dup do
  desc "List possible duplicate feeds"
  task :list => [:environment] do
    groups = get_duplicate_groups
    groups.keys.sort.each do |title|
      puts "#{title}  => [#{groups[title].map(&:id).join(",")}]"
    end
    
    puts "#{groups.values.inject(0) { |memo,arr| memo + arr.size }} Potential duplicates grouped into #{groups.size} feeds"
  end
  
  desc "Mark as tombstones all duplicates with zero items"
  task :tombstonify => :environment do
    tombstones = 0
    get_duplicate_groups.each do |(title, feeds)|
      survivors = feeds.select {|f| f.feed_items.size > 0 }
      if survivors.size == 1
        puts "Creating tombstones for duplicates of #{title}"
        (feeds - survivors).each do |tombstone|
          tombstones += 1
          tombstone.duplicate_id = survivors.first.id
          tombstone.save          
        end
      else
        puts "Won't tombstone #{title} since it has more than one feed with items"
      end      
    end
    
    puts "Created #{tombstones} tombstones"
  end
  
  desc "Merge items from duplicates and mark the left over feeds as a tombstone - implies tombstonify"
  task :merge => :environment do
    puts "Press CTRL-c at any time to abort."
    
    Feed.transaction do
      get_duplicate_groups.each do |(title, feeds)|
        puts "Feed '#{title}' has #{feeds.size} candidates:"
        feeds.each_with_index do |feed, i|
          puts "\t#{i+1}. #{feed.feed_items.size} items from #{feed.url}"
        end
        
        survivor = nil
        until (0...feeds.size).include?(survivor) || survivor == -1
          print "Enter the index of the feed that should survive (0 to skip): "
          survivor = STDIN.readline.to_i - 1
        end

        if survivor >= 0
          survivor = feeds[survivor]
          puts "The survivor is #{survivor.url}"
          (feeds - [survivor]).each do |condemned|
            condemned.feed_items.each do |fi|
              fi.feed = survivor
              fi.save
            end
            condemned.duplicate_id = survivor.id
            condemned.save
          end
        else
          puts "Skipped"
        end
      end
    end
  end
  
  def get_duplicate_groups
    dups = Feed.search(:mode => "duplicates")
    groups = dups.group_by(&:title)
    groups.map do |(title, feeds)|
      title if feeds.size < 2
    end.each do |title|
      groups.delete(title)
    end    
    groups
  end
end
