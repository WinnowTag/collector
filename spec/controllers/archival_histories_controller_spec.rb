require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'

describe ArchivalHistoriesController do
  fixtures :archival_histories, :users

  before(:each) do
    login_as(:admin)
  end

  it "should_get_index" do
    get :index
    assert_response :success
    assert assigns(:archival_histories)
  end
  
  it "index_for_atom" do
    accept('application/atom+xml')
    get :index
    assert_template 'atom'
  end
end
