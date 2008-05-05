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
              fi.feed = feeds[survivor]
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
    dups = Feed.find_duplicates()
    groups = dups.group_by(&:title)
    groups.map do |(title, feeds)|
      title if feeds.size < 2
    end.each do |title|
      groups.delete(title)
    end    
    groups
  end
end
