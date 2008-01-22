require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'
require 'feeds_controller'

# Re-raise errors caught by the controller and skip authentication.
class FeedsController; def rescue_action(e) raise e end; end

describe FeedsController do
  fixtures :feeds, :users, :collection_errors
  
  before(:each) do
    login_as(:admin)
  end

  describe 'CRUD operations' do
    integrate_views
    
    def test_requires_login
      assert_requires_login() {|c| c.get :index, {} }
    end
  
    def test_create_doesnt_require_login_if_request_is_local
      @controller.stub!(:local_request?).and_return(true)
      @request.session[:user] = nil
      assert_difference(Feed, :count) do
        post :create, :feed => {:url => "http://newfeed"}
        assert_redirected_to feeds_url
        assert Feed.find_by_url("http://newfeed")
      end
    end
   
    def test_create_requires_login_if_request_is_not_local
      @request.session[:user] = nil
      assert_difference(Feed, :count, 0) do
        assert_requires_login {|c| c.post :create, :feed => {:url => "http://newfeed"} }
      end
    end
  
    def test_index_sets_feeds_instance_variable
      get :index
      assert_equal(Feed.count(:conditions => ['is_duplicate = ?', false]), assigns(:feeds).size)
    end
  
    def test_with_recent_errors_shows_feeds_with_recent_errors
      get :with_recent_errors
      assert_template 'index'
      assert_equal([Feed.find(1)], assigns(:feeds))
    end
  
    def test_with_recent_errors_shows_feeds_with_recent_errors_once
      Feed.find(1).collection_errors.create(:exception => Exception.new('test'))
      get :with_recent_errors
      assert_template 'index'
      assert_equal([Feed.find(1)], assigns(:feeds))
    end
  
    def test_duplicates_shows_duplicates
      feed = Feed.find(1)
      dup = Feed.new(:url => 'http://foo')
      dup.link = feed.link
      dup.save!
      get :duplicates
      assert_template 'index'
      assert_equal([feed, dup].sort_by{|a| a.id}, assigns(:feeds).sort_by{|a| a.id})
    end
  
    def test_list_provides_text_format
      accept('text/plain')
      get :index
      assert_response :success
      assert_equal Feed.find(:all).map(&:url).join("\n"), @response.body
    end
  
    def test_new_shows_form
      get :new
      assert_response :success
      assert_select('form[action="/feeds"]', 1, @response.body)
    end
    
    def test_create_with_duplicate_url_redirects_to_duplicate
      post :create, :feed => {:url => Feed.find(1).url}
      assert_redirected_to feed_url(Feed.find(1))
    end
  
    def test_create_with_duplicate_placeholder_url_redirects_to_duplicate
      post :create, :feed => {:url => feeds(:duplicate_feed).url}
      assert_redirected_to feed_url(feeds(:duplicate_feed).duplicate)
    end
  
    def test_create_with_invalid_url_fails
      post :create, :feed => {:url => '####'}
      assert_response :success
      assert_select("div.fieldWithErrors input#feed_url", 1, @response.body)
    end
  
    def test_rest_create_with_duplicate_url_redirects_to_duplicate
      accept("application/xml")
      post :create, :feed => {:url => Feed.find(1).url}
      assert_redirected_to feed_url(Feed.find(1))
    end
  
    def test_rest_create_with_duplicate_placeholder_url_redirects_to_duplicate
      accept("application/xml")
      post :create, :feed => {:url => feeds(:duplicate_feed).url}
      assert_redirected_to feed_url(feeds(:duplicate_feed).duplicate)
    end  
    
    def test_create_accepting_xml   
      assert_difference(Feed, :count) do
        accept('application/xml')
        post :create, :feed => {:url => 'http://test.feed/'}
        assert feed = Feed.find_by_url('http://test.feed/')
        assert_equal("application/xml", @response.content_type)
        assert_equal(feed_url(feed), @response.headers['Location'])
        assert_response 201
      end
    end
  
    def test_create_with_invalid_url_sets_422_when_accepting_xml
      assert_difference(Feed, :count, 0) do
        accept("application/xml")
        post :create, :feed => {:url => '####'}
        assert_response 422
      end
    end
        
    def test_destroy_fails_with_get
      get :destroy
      assert_response 400
    end
  
    def test_destroy_works_with_post
      referer('/feeds')
      feed = Feed.create(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
      delete :destroy, :id => feed.id
      assert_response :redirect
      assert_redirected_to '/feeds'
      assert_equal 'http://rss.slashdot.org/Slashdot/slashdot has been removed', flash[:notice]
      assert_raise ActiveRecord::RecordNotFound do
        Feed.find(feed.id)
      end
    end
  
    def test_get_import_returns_form
      get :import
      assert_response :success
      assert_select("form[action = '/feeds/import']", 1, @response.body)
    end
  
    def test_import_without_urls_fails
      post :import
      assert_response :success
      assert_select("#error", "You must enter at least one feed url", @response.body)
    end
  
    def test_post_import_with_single_url
      post :import, :feed => {:urls => 'http://rss.slashdot.org/Slashdot/slashdot'}
      assert_response :redirect
      assert_redirected_to feeds_url
      assert_equal '1 new feed added', flash[:notice]
    
      # Check the Feed was created
      assert_not_nil Feed.find_by_url('http://rss.slashdot.org/Slashdot/slashdot')
    end
  
    def test_post_import_with_multiple_urls
      post :import, :feed => {:urls => "http://rss.slashdot.org/Slashdot/slashdot\nhttp://rss.slashdot.org/Slashdot/slashdotDevelopers"}
      assert_response :redirect
      assert_redirected_to feeds_url
      assert_equal '2 new feeds added', flash[:notice]
    end
  
    def test_importing_duplicate_single_feeds_fails
      Feed.create(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
      post :import, :feed => {:urls => 'http://rss.slashdot.org/Slashdot/slashdot'}
      assert_response :success
      assert_template 'import'
      assert_select("#error", "1 Feed already exists", @response.body)
    end
  
    def test_importing_duplicate_multiple_feeds_fails
      Feed.create(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
      post :import, :feed => {:urls => "http://rss.slashdot.org/Slashdot/slashdot\nhttp://rss.slashdot.org/Slashdot/slashdotDevelopers"}
      assert_response :success
      assert_template 'import'
      assert_select("#notice", "1 new feed added", @response.body)
      assert_select("#error", "1 Feed already exists", @response.body)
      assert_equal 'http://rss.slashdot.org/Slashdot/slashdot', assigns(:urls)
    end

    def test_importing_opml_via_rest
      assert_difference(Feed, :count, 13) do
        accept("application/xml")
        opml_data = File.read(File.join(RAILS_ROOT, "spec", "fixtures", "example.opml"))
    
        post :import_opml, :opml => Opml.parse(opml_data)
        assert_response :success
        assert_select("feed", 13, @response.body)
      
        assert_not_equal([], assigns(:feeds).map(&:title).compact)
      end
    end
  
    def test_show_without_id_redirects_to_index
      get :show
      assert_redirected_to feeds_url
    end
  
    def test_show_returns_xml
      accept("text/xml")
      get :show, :id => 1
      assert_match(/application\/xml/, @response.content_type)
    end
  

  
    def test_show_assigns_feed
      get :show, :id => 1
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:feed)
      assert_equal Feed.find(1), assigns(:feed)
    end
  
    def test_show_with_duplicate_place_holder_redirects_to_duplicate
      feed = feeds(:duplicate_feed)
      get :show, :id => feed.id
      assert_redirected_to feed_url(feed.duplicate)    
    end
  
    def test_update_with_get_redirects_to_index
      get :update, :id => 1
      assert_response 400
    end
  
    def test_update_without_id_redirects_to_index
      post :update
      assert_redirected_to feeds_url
    end
  
    def test_update_with_protected_attributes_fails
      post :update, :id => 1, :feed => {:title => 'Title', :url => 'http://test', :active => true}
      assert_redirected_to feeds_url
      assert_not_equal("http://test", Feed.find(1).url)
    end
  
    def test_update_using_ajax
      accept('text/javascript')
      post :update, :id => 1, :feed => {:active => false}
      assert_response :success
      assert_nil flash[:error]
      assert !Feed.find(1).active?
    end
  end
  
  describe "show.atom.builder" do
    integrate_views
    
    before(:each) do
      @feed = mock_model(Feed, valid_feed_attributes(:is_duplicate? => false))      
      @feed_items = WillPaginate::Collection.create(1, 40) do |pager|
        pager.replace([])
        pager.total_entries = 0
      end
      @feed.stub!(:feed_items).and_return(stub('feed_items', :paginate => @feed_items))
      Feed.stub!(:find).and_return(@feed)
    end
    
    def do_get
      accept("application/atom+xml")
      get :show, :id => 1
    end
    
    it "should return atom" do      
      do_get
      response.content_type.should match(/application\/atom\+xml/)
    end

    it "should render a feed element" do
      do_get
      response.body.should have_tag('feed')
    end

    it "should render the atom namespace" do
      do_get
      response.body.should have_tag("feed[xmlns = '#{Atom::NAMESPACE}']")
    end

    it "should render the feed title" do
      do_get
      response.should have_tag('feed title', @feed.title)
    end

    it "should render the self link to point back to itself" do
      do_get
      response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom'][type = 'application/atom+xml'][rel = 'self']")
    end

    it "should render an alternate link as the source html page" do
      do_get
      response.should have_tag("feed link[href = '#{@feed.link}'][type = 'text/html'][rel = 'alternate']")
    end

    it "should render an via link as the source feed" do
      do_get
      response.should have_tag("feed link[href = '#{@feed.url}'][rel = 'via']")
    end

    it "should render an id in the form urn:peerworks.org:feed#id" do
      do_get
      response.should have_tag('feed id', "urn:peerworks.org:feed##{@feed.id}")
    end

    it "should render an updated date" do
      do_get
      response.should have_tag('feed updated', @feed.updated_on.xmlschema)
    end

    describe 'single page feed' do
      integrate_views
      before(:each) do
        @item = mock_model(FeedItem, valid_feed_item_attributes(:author => 'John Doe', 
                    :content => mock('content', :encoded_content => '<p>encoded content</p>') ))
        @feed_items = WillPaginate::Collection.create(1, 40) do |pager|
          pager.replace([@item])
        end
        @feed.stub!(:feed_items).and_return(stub('feed_items', :paginate => @feed_items))
      end

      it "should render a first link pointing to self" do
        do_get
        response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom'][rel = 'first']")
      end

      it "should render a last link pointing to self" do
        do_get
        response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom'][rel = 'last']", true, response.body)
      end

      it "should not render a next" do
        do_get
        response.should_not have_tag("feed link[rel = 'next']")
      end

      it "should not render a prev" do
        do_get
        response.should_not have_tag('feed link[rel = "next"]')
      end

      describe 'item rendering' do
        integrate_views
        
        it "should have 1 entry" do
          do_get
          response.should have_tag('feed entry', 1)
        end

        it "should have an id for the entry" do
          do_get
          response.should have_tag('feed entry id', "urn:peerworks.org:entry##{@item.id}")
        end

        it "should have a title" do
          do_get
          response.should have_tag('feed entry title', @item.title)
        end

        it "should have an updated date" do
          do_get
          response.should have_tag('feed entry updated', @item.time.xmlschema)
        end

        it "should have an author" do
          do_get
          response.should have_tag('feed entry author name', @item.author)
        end

        it "should have content encoded as HTML" do
          do_get
          response.should have_tag('feed entry content[type="html"]', escape_once(@item.content.encoded_content), response.body)
        end

        it "should have http://collector.wizztag.org/rel/spider pointing the spider url" do
          do_get
          response.should have_tag("feed entry link[rel = 'http://peerworks.org/rel/spider']" +
                                   "[href = '#{spider_feed_item_url(@item)}']")
        end

        it "should have self pointing to the entry document" do
          do_get
          response.should have_tag("feed entry link[rel = 'self'][href = '#{feed_item_url(@item)}.atom']")
        end

        it "should have an alternate pointing to source alternate" do
          do_get
          response.should have_tag("feed entry link[rel = 'alternate'][href = '#{@item.link}']")
        end
      end
    end

    describe "multi page feed" do
      integrate_views
      before(:each) do
        @feed_items = WillPaginate::Collection.create(2, 40) do |pager|
          items = []
          40.times do
            items << mock_model(FeedItem, valid_feed_item_attributes(:author => 'author', :content => nil))
          end

          pager.replace(items)
          pager.total_entries = 135
        end
        @feed.stub!(:feed_items).and_return(stub('feed_items', :paginate => @feed_items))
      end

      it "should render a first link without a page number" do
        do_get
        response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom'][rel = 'first']")
      end

      it "should render a last link pointing to the last page" do
        do_get
        response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom?page=4'][rel = 'last']")
      end

      it "should render a prev link pointing page 1" do
        do_get
        response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom?page=1'][rel = 'prev']")
      end

      it "should render a next link pointing to page 3" do
        do_get
        response.should have_tag("feed link[href = '#{feed_url(@feed)}.atom?page=3'][rel = 'next']")
      end

      it "should have all the entries" do
        do_get
        response.should have_tag('feed entry', 40)
      end
    end
  end
end
