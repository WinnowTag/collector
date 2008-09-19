# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe FeedsController do
  fixtures :feeds, :users, :collection_errors
  
  before(:each) do
    login_as(:admin)
  end

  describe 'CRUD operations' do    
    it "requires_login" do
      assert_requires_login() {|c| c.get :index, {} }
    end
  
    it "create_doesnt_require_login_if_request_is hmac authenticated" do
      @controller.should_receive(:hmac_authenticated?).and_return(true)
      @request.session[:user] = nil
      assert_difference(Feed, :count) do
        post :create, :feed => {:url => "http://newfeed"}
        assert_redirected_to feeds_url
        assert Feed.find_by_url("http://newfeed")
      end
    end
   
    it "create_requires_login_if_request_is_not_hmac authenticated" do
      @request.session[:user] = nil
      assert_difference(Feed, :count, 0) do
        assert_requires_login {|c| c.post :create, :feed => {:url => "http://newfeed"} }
      end
    end
  
    it "index_sets_feeds_instance_variable" do
      get :index
      assert_equal(Feed.count(:conditions => ['duplicate_id is NULL']), assigns(:feeds).size)
    end
  
    it "with_recent_errors_shows_feeds_with_recent_errors_once" do
      feed = Feed.find(1)
      job = feed.collection_jobs.create!
      job.collection_error = CollectionError.create(:exception => Exception.new('test'))
      feed.save!
      get :with_recent_errors
      assert_template 'index'
      assert_equal([Feed.find(1)], assigns(:feeds))
    end
  
    it "duplicates_shows_duplicates" do
      feed = Feed.find(1)
      dup = Feed.new(:url => 'http://foo')
      dup.link = feed.link
      dup.save!
      get :duplicates
      assert_template 'index'
      assert_equal([feed, dup].sort_by{|a| a.id}, assigns(:feeds).sort_by{|a| a.id})
    end
    
    it "duplicates_doesnt_show_duplicate_tombstones" do
      feed = Feed.find(1)
      dup = Feed.new(:url => 'http://foo')
      dup.link = feed.link
      dup.duplicate = feed
      dup.save!
      get :duplicates
      assert_equal([], assigns[:feeds])
    end
  
    it "list_provides_text_format" do
      accept('text/plain')
      get :index
      assert_response :success
      assert_equal Feed.find(:all).map(&:url).join("\n"), @response.body
    end

    it "create_with_duplicate_url_redirects_to_duplicate" do
      post :create, :feed => {:url => Feed.find(1).url}
      assert_redirected_to feed_url(Feed.find(1))
    end
  
    it "create_with_duplicate_placeholder_url_redirects_to_duplicate" do
      post :create, :feed => {:url => feeds(:duplicate_feed).url}
      assert_redirected_to feed_url(feeds(:duplicate_feed).duplicate)
    end    
  
    it "should fail when created with an invalid url" do
      post :create, :feed => {:url => '####'}
      response.should render_template('feeds/new')
    end
    
    it "should set created_by on the feed if it is provided" do
      post :create, :feed => {:url => 'http://test.feed', :created_by => 'quentin'}
      Feed.find_by_url('http://test.feed').created_by.should == 'quentin'
    end
  
    it "rest_create_with_duplicate_url_redirects_to_duplicate" do
      accept("application/xml")
      post :create, :feed => {:url => Feed.find(1).url}
      assert_redirected_to feed_url(Feed.find(1))
    end
  
    it "rest_create_with_duplicate_placeholder_url_redirects_to_duplicate" do
      accept("application/xml")
      post :create, :feed => {:url => feeds(:duplicate_feed).url}
      assert_redirected_to feed_url(feeds(:duplicate_feed).duplicate)
    end  
    
    it "create_accepting_xml   " do
      assert_difference(Feed, :count) do
        accept('application/xml')
        post :create, :feed => {:url => 'http://test.feed/'}
        assert feed = Feed.find_by_url('http://test.feed/')
        assert_equal("application/xml", @response.content_type)
        assert_equal(feed_url(feed), @response.headers['Location'])
        assert_response 201
      end
    end
  
    it "create_with_invalid_url_sets_422_when_accepting_xml" do
      assert_difference(Feed, :count, 0) do
        accept("application/xml")
        post :create, :feed => {:url => '####'}
        assert_response 422
      end
    end
        
    it "destroy_fails_with_get" do
      get :destroy
      assert_response 400
    end
  
    it "destroy_works_with_post" do
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
  
    it "post_import_with_single_url" do
      post :import, :feed => {:urls => 'http://rss.slashdot.org/Slashdot/slashdot'}
      assert_response :redirect
      assert_redirected_to feeds_url
      assert_equal '1 new feed added', flash[:notice]
    
      # Check the Feed was created
      assert_not_nil Feed.find_by_url('http://rss.slashdot.org/Slashdot/slashdot')
    end
  
    it "post_import_with_multiple_urls" do
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
  
    it "importing_duplicate_multiple_feeds_fails" do
      Feed.create(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
      post :import, :feed => {:urls => "http://rss.slashdot.org/Slashdot/slashdot\nhttp://rss.slashdot.org/Slashdot/slashdotDevelopers"}
      response.should render_template('feeds/import')
      # TODO fix expections for flash.now[:error]
      # flash[:error].should == '1 Feed already exists'
      flash[:notice].should == '1 new feed added'
    end

    it "importing_opml_via_rest" do
      assert_difference(Feed, :count, 13) do
        accept("application/xml")
        opml_data = File.read(File.join(RAILS_ROOT, "spec", "fixtures", "example.opml"))
    
        post :import_opml, :opml => Opml.parse(opml_data)
        assert_response :success
        assert_select("feed", 13, @response.body)
      
        assert_not_equal([], assigns(:feeds).map(&:title).compact)
      end
    end
  
    it "show_without_id_redirects_to_index" do
      get :show
      assert_redirected_to feeds_url
    end
  
    it "show_returns_xml" do
      accept("text/xml")
      get :show, :id => 1
      assert_match(/application\/xml/, @response.content_type)
    end

    it "show_assigns_feed" do
      get :show, :id => 1
      assert_response :success
      assert_template 'show'
      assert_not_nil assigns(:feed)
      assert_equal Feed.find(1), assigns(:feed)
    end
  
    it "show_with_duplicate_place_holder_redirects_to_duplicate" do
      feed = feeds(:duplicate_feed)
      get :show, :id => feed.id
      assert_redirected_to feed_url(feed.duplicate)    
    end
  
    it "update_with_get_redirects_to_index" do
      get :update, :id => 1
      assert_response 400
    end
  
    it "update_without_id_redirects_to_index" do
      post :update
      assert_redirected_to feeds_url
    end
  
    it "update_with_protected_attributes_fails" do
      post :update, :id => 1, :feed => {:title => 'Title', :url => 'http://test', :active => true}
      assert_redirected_to feeds_url
      assert_not_equal("http://test", Feed.find(1).url)
    end
  
    it "update_using_ajax" do
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
