xml.instruct! :xml, :version => '1.0'
xml.feed :xmlns => Atom::NAMESPACE do
  xml.title @feed.title
  xml.id "urn:peerworks.org:feed##{@feed.id}"
  xml.updated @feed.updated_on.xmlschema
  
  xml.link :href => "#{feed_url(@feed)}.atom", :type => 'application/atom+xml', :rel => 'self'
  xml.link :href => "#{@feed.url}", :rel => 'via'
  xml.link :href => "#{@feed.link}", :type => 'text/html', :rel => 'alternate'
  xml.link :href => "#{feed_url(@feed)}.atom", :type => 'application/atom+xml', :rel => 'first'
  
  if @feed_items.page_count == 1
    xml.link :href => "#{feed_url(@feed)}.atom", :rel => 'last', :type => 'application/atom+xml'
  else
    xml.link :href => "#{feed_url(@feed)}.atom?page=#{@feed_items.page_count}", 
             :rel => 'last', :type => 'application/atom+xml'
  end
  
  if @feed_items.previous_page
    xml.link :href => "#{feed_url(@feed)}.atom?page=#{@feed_items.previous_page}", 
             :type => 'application/atom+xml', :rel => 'prev'
  end
  
  if @feed_items.next_page
    xml.link :href => "#{feed_url(@feed)}.atom?page=#{@feed_items.next_page}", 
             :type => 'application/atom+xml', :rel => 'next'
  end
  
  @feed_items.each do |feed_item|
    xml.entry do
      xml.title feed_item.title
      xml.id "urn:peerworks.org:entry##{feed_item.id}"
      xml.updated feed_item.time.xmlschema
      if feed_item.author
        xml.author do
          xml.name feed_item.author
        end
      end
      xml.link :href => "#{feed_item_url(feed_item)}.atom", :rel => 'self'
      xml.link :href => spider_feed_item_url(feed_item), :rel => 'http://peerworks.org/rel/spider'
      if feed_item.link
        xml.link :href => feed_item.link, :rel => 'alternate'
      end
      xml.content feed_item.content.encoded_content, :type => 'html' unless feed_item.content.nil?
    end
  end
end
