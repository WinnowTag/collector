# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
require File.dirname(__FILE__) + '/../spec_helper'

describe CollectionSummariesController do
  fixtures :collection_summaries, :users

  before(:each) do
    login_as(:admin)
  end

  it "should_get_index" do
    get :index
    response.should be_success
  end

  # TODO: Move to view spec
  # it "index_should_contain_row_for_each_summary" do
  #   get :index
  #   assert_select("table.data_table", true, @response.body) do
  #     assert_select('tr', CollectionSummary.count + 1, @response.body)
  #   end
  # end
  # 
  # it "index_should_contain_link_to_show_for_each_summary" do
  #   get :index
  #   CollectionSummary.find(:all).each do |s|
  #     assert_select("a[href=#{collection_summary_path(s)}]", true)
  #   end
  # end
  
  it "index_for_atom" do
    accept('application/atom+xml')
    get :index
    assert_template 'index'
  end
  
  it "index_for_atom_without_login_returns_403" do
    accept('application/atom+xml')
    login_as(nil)
    get :index
    assert_response 401
  end
  
  it "should_show_collection_summary" do
    get :show, :id => 1
    assert_response :success
  end
end
