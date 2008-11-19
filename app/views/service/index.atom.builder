xml.instruct! :xml, :version => '1.0'
xml.service :xmlns => Atom::Pub::NAMESPACE, :'xmlns:atom' => Atom::NAMESPACE do
  xml.workspace do
    xml.atom :title, 'Peerworks Collector'
    @feeds.each do |feed|
      xml.collection :href => formatted_feed_url(feed, :atom) do
        xml.atom :title, feed.title
        xml.accept
      end
    end
  end
end
