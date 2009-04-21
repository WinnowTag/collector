xml.instruct! :xml, :version => '1.0'
xml.service :xmlns => Atom::Pub::NAMESPACE, :'xmlns:atom' => Atom::NAMESPACE do
  xml.workspace do
    xml.atom :title, 'Peerworks Collector'
    @feeds.each do |feed|
      xml.collection :href => feed_url(feed, :format => :atom) do
        xml.atom :title, feed.title
        xml.accept
      end
    end
  end
end
