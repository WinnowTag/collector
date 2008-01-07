require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'
require 'collection_summaries_controller'

# Re-raise errors caught by the controller.
class CollectionSummariesController; def rescue_action(e) raise e end; end

class CollectionSummariesControllerTest < Test::Unit::TestCase
  fixtures :collection_summaries, :users

  def setup
    @controller = CollectionSummariesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)
  end

  def test_should_get_index
    get :index
    assert_response :success
    assert assigns(:collection_summaries)
  end
  
  def test_index_should_contain_row_for_each_summary
    get :index
    assert_select("table.data_table", true, @response.body) do
      assert_select('tr', CollectionSummary.count + 1, @response.body)
    end
  end
  
  def test_index_should_contain_link_to_show_for_each_summary
    get :index
    CollectionSummary.find(:all).each do |s|
      assert_select("a[href=#{collection_summary_path(s)}]", true)
    end
  end
  
  def test_index_for_atom
    accept('application/atom+xml')
    get :index
    assert_template 'atom'
  end
  
  def test_index_for_atom_without_login_returns_403
    accept('application/atom+xml')
    login_as(nil)
    get :index
    assert_response 401
  end
  
  def test_should_show_collection_summary
    get :show, :id => 1
    assert_response :success
  end
end
