require "#{File.dirname(__FILE__)}/../test_helper"

class OpmlIntegrationTest < ActionController::IntegrationTest
  # fixtures :your, :models

  # Replace this with your real tests.
  def test_import_opml
    assert_difference(Feed, :count, 13) do
      opml_data = File.read(File.join(RAILS_ROOT, "test", "fixtures", "example.opml"))
      
      post import_opml_feeds_url, opml_data, 
                      'Content-Length' => opml_data.size, 
                      'Content-Type' => 'text/x-opml', 
                      'Accept' => 'text/xml'
      assert_response :success
      assert_select("feed", 13, @response.body)
    end
  end
end
