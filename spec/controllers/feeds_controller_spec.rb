# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
        assert_response 201
        assert Feed.find_by_url("http://newfeed")
      end
    end
   
    it "create_requires_login_if_request_is_not_hmac authenticated" do
      @request.session[:user] = nil
      assert_difference(Feed, :count, 0) do
        assert_requires_login {|c| c.post :create, :feed => {:url => "http://newfeed"} }
      end
    end
  
    it "list_provides_text_format" do
      accept('text/plain')
      get :index
      assert_response :success
      assert_equal Feed.find(:all).map(&:url).join("\n"), @response.body
    end

    it "create_with_duplicate_url_redirects_to_duplicate" do
      post :create, :feed => {:url => Feed.find(1).url}
      assert_redirected_to feed_url(:id => Feed.find(1).uri)
    end
  
    it "create_with_duplicate_placeholder_url_redirects_to_duplicate" do
      post :create, :feed => {:url => feeds(:duplicate_feed).url}
      assert_redirected_to feed_url(:id => feeds(:duplicate_feed).duplicate.uri)
    end    
  
    it "should fail when created with an invalid url" do
      post :create, :feed => {:url => '####'}
      assert_response 422
    end
    
    it "should set created_by on the feed if it is provided" do
      post :create, :feed => {:url => 'http://test.feed', :created_by => 'quentin'}
      Feed.find_by_url('http://test.feed').created_by.should == 'quentin'
    end
  
    it "rest_create_with_duplicate_url_redirects_to_duplicate" do
      accept("application/xml")
      post :create, :feed => {:url => Feed.find(1).url}
      assert_redirected_to feed_url(:id => Feed.find(1).uri)
    end
  
    it "rest_create_with_duplicate_placeholder_url_redirects_to_duplicate" do
      accept("application/xml")
      post :create, :feed => {:url => feeds(:duplicate_feed).url}
      assert_redirected_to feed_url(:id => feeds(:duplicate_feed).duplicate.uri)
    end  
    
    it "create_accepting_xml   " do
      assert_difference(Feed, :count) do
        accept('application/xml')
        post :create, :feed => {:url => 'http://test.feed/'}
        assert feed = Feed.find_by_url('http://test.feed/')
        assert_equal("application/xml", @response.content_type)
        assert_equal(feed_url(:id => feed.uri), @response.headers['Location'])
        assert_response 201
        assert_select("feed uri")
      end
    end
  
    it "create_with_invalid_url_sets_422_when_accepting_xml" do
      assert_difference(Feed, :count, 0) do
        accept("application/xml")
        post :create, :feed => {:url => '####'}
        assert_response 422
      end
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
  
    it "should fail when importing without a feed[urls]" do
      post :import
      response.should redirect_to(feeds_path)
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
      response.should render_template('feeds/index')
      flash[:error].should == '1 Feed already exists'
    end
  
    it "importing_duplicate_multiple_feeds_fails" do
      Feed.create(:url => 'http://rss.slashdot.org/Slashdot/slashdot')
      post :import, :feed => {:urls => "http://rss.slashdot.org/Slashdot/slashdot\nhttp://rss.slashdot.org/Slashdot/slashdotDevelopers"}
      response.should render_template('feeds/index')
      flash[:error].should == '1 Feed already exists'
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
  
    it "show_returns_xml" do
      accept("text/xml")
      get :show, :id => 1
      assert_match(/application\/xml/, @response.content_type)
    end
    
    it "should respond to show with uuid" do
      accept("text/xml")
      get :show, :id => Feed.find(1).uri
      response.should be_success
    end

    it "should assign feed with uuid" do
      accept("text/xml")
      get :show, :id => Feed.find(1).uri
      assigns(:feed).should == Feed.find(1)
    end
    
    it "should return 404 if uuid is missing" do
      lambda { get(:show, :id => "urn:uuid:blah") }.should raise_error(ActiveRecord::RecordNotFound)
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
  
    it "update_with_protected_attributes_fails" do
      put :update, :id => 1, :feed => {:title => 'Title', :url => 'http://test', :active => true}
      response.should be_success
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

    xit "should return atom" do      
      @feed.should_receive(:to_atom).with(:base => 'http://test.host:80', :include_entries => true, :page => nil)
      accept("application/atom+xml")
      get :show, :id => 1, :format => :atom
      response.content_type.should match(/application\/atom\+xml/)
    end
  end
end
