require File.dirname(__FILE__) + '/../test_helper'
require 'feeds_controller'

# Re-raise errors caught by the controller and skip authentication.
class FeedsController; def rescue_action(e) raise e end; end

class FeedsControllerTest < Test::Unit::TestCase
  fixtures :feeds, :users
  
  def setup
    @controller = FeedsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)
  end

  def test_requires_login
    assert_requires_login() {|c| c.get :index, {} }
  end
  
  def test_create_doesnt_require_login_if_request_is_local
    @controller.stubs(:local_request?).returns(true)
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
    assert_equal(Feed.count, assigns(:feeds).size)
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
    
  def test_create_with_duplicate_url_fails
    post :create, :feed => {:url => Feed.find(1).url}
    assert_response :success
    assert_select("div.fieldWithErrors input#feed_url", 1, @response.body)
  end
  
  def test_create_with_invalid_url_fails
    post :create, :feed => {:url => '####'}
    assert_response :success
    assert_select("div.fieldWithErrors input#feed_url", 1, @response.body)
  end
    
  def test_create_accepting_xml   
    assert_difference(Feed, :count) do
      accept('application/xml')
      post :create, :feed => {:url => 'http://test.feed/'}
      assert feed = Feed.find_by_url('http://test.feed/')
      assert_equal("application/xml; charset=utf-8", @response.headers['Content-Type'])
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
    feed = Feed.create(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
    delete :destroy, :id => feed.id
    assert_response :redirect
    assert_redirected_to ''
    assert_equal 'http://rss.slashdot.org/Slashdot/slashdot has been removed', flash[:notice]
    assert_raise ActiveRecord::RecordNotFound do
      Feed.find(feed.id)
    end
  end
  
  def test_get_import_returns_form
    get :import
    assert_response :success
    assert_select("form[action = '/feeds;import']", 1, @response.body)
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
    assert_select("#error", "1 feed already exists", @response.body)
  end
  
  def test_importing_duplicate_multiple_feeds_fails
    Feed.create(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
    post :import, :feed => {:urls => "http://rss.slashdot.org/Slashdot/slashdot\nhttp://rss.slashdot.org/Slashdot/slashdotDevelopers"}
    assert_response :success
    assert_template 'import'
    assert_select("#notice", "1 new feed added", @response.body)
    assert_select("#error", "1 feed already exists", @response.body)
    assert_equal 'http://rss.slashdot.org/Slashdot/slashdot', assigns(:urls)
  end

  def test_show_without_id_redirects_to_index
    get :show
    assert_redirected_to feeds_url
  end
  
  def test_show_returns_xml
    accept("text/xml")
    get :show, :id => 1
    assert_match(/application\/xml/, @response.headers['Content-Type'])
  end
  
  def test_show_assigns_feed
    get :show, :id => 1
    assert_response :success
    assert_template 'show'
    assert_not_nil assigns(:feed)
    assert_equal Feed.find(1), assigns(:feed)
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
