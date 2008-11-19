xml.instruct!

xml.feed "xmlns" => "http://www.w3.org/2005/Atom" do

  xml.title   "Winnow Collection History"
  xml.link    "rel" => "self", "href" => formatted_collection_summaries_url(:atom)
  xml.link    "rel" => "alternate", "href" => collection_summaries_url
  xml.id      collection_summaries_url
  xml.updated @collection_summaries.first.updated_on.strftime("%Y-%m-%dT%H:%M:%SZ") if @collection_summaries.any?
  xml.author  { xml.name "Peerworks" }

  @collection_summaries.each do |collection_summary|
    xml.entry do
      xml.title   "Collection for #{collection_summary.created_on.to_formatted_s('%d %b')}"
      xml.link    "rel" => "alternate", "href" => collection_summary_url(collection_summary)
      xml.id      collection_summary_url(collection_summary)
      xml.updated collection_summary.updated_on.strftime("%Y-%m-%dT%H:%M:%SZ")
      xml.content "type" => "html" do
        xml.text! atom_summary(collection_summary)
      end
    end
  end
end
