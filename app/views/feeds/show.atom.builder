xml.instruct! :xml, :version => '1.0'
xml.feed :xmlns => Atom::NAMESPACE do
  xml.title @feed.title
  xml.id "urn:peerworks.org:feed##{@feed.id}"
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
end
