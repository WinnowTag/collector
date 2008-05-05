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
    
    def test_duplicates_doesnt_show_duplicate_tombstones
      feed = Feed.find(1)
      dup = Feed.new(:url => 'http://foo')
      dup.link = feed.link
      dup.duplicate = feed
      dup.save!
      get :duplicates
      assert_equal([], assigns[:feeds])
    end
  
    def test_list_provides_text_format
      accept('text/plain')
      get :index
      assert_response :success
      assert_equal Feed.find(:all).map(&:url).join("\n"), @response.body
    end

    def test_create_with_duplicate_url_redirects_to_duplicate
      post :create, :feed => {:url => Feed.find(1).url}
      assert_redirected_to feed_url(Feed.find(1))
    end
  
    def test_create_with_duplicate_placeholder_url_redirects_to_duplicate
      post :create, :feed => {:url => feeds(:duplicate_feed).url}
      assert_redirected_to feed_url(feeds(:duplicate_feed).duplicate)
    end
  
    it "should fail when created with an invalid url" do
      post :create, :feed => {:url => '####'}
      response.should render_template('feeds/new')
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
  
    it "should render the import form in response to GET /import" do
      get :import
      response.should be_success
      response.should render_template('feeds/import')
    end
  
    it "should fail when importing without a feed[urls]" do
      post :import
      response.should render_template('feeds/import')
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
  
    it "should fail when importing a duplicate" do
      Feed.create!(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
      post :import, :feed => {:urls => 'http://rss.slashdot.org/Slashdot/slashdot'}
      response.should render_template('feeds/import')
      # TODO get this working
      #flash.now[:error].should == '1 Feed already exists'
    end
  
    def test_importing_duplicate_multiple_feeds_fails
      Feed.create(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
      post :import, :feed => {:urls => "http://rss.slashdot.org/Slashdot/slashdot\nhttp://rss.slashdot.org/Slashdot/slashdotDevelopers"}
      response.should render_template('feeds/import')
      # TODO fix expections for flash.now[:error]
      # flash[:error].should == '1 Feed already exists'
      flash[:notice].should == '1 new feed added'
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
  
  describe 'GET /feeds/:id with atom' do
    before(:each) do
      @feed = mock_model(Feed, valid_feed_attributes(:is_duplicate? => false))      
      Feed.stub!(:find).and_return(@feed)
    end

    it "should return atom" do      
      @feed.should_receive(:to_atom).with(:base => 'http://test.host:80', :include_entries => true, :page => nil)
      accept("application/atom+xml")
      get :show, :id => 1
      response.content_type.should match(/application\/atom\+xml/)
    end
  end
end
