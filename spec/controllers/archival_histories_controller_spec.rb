require File.dirname(__FILE__) + '/../test_helper'
require File.dirname(__FILE__) + '/../spec_helper'
require 'archival_histories_controller'

# Re-raise errors caught by the controller.
class ArchivalHistoriesController; def rescue_action(e) raise e end; end

class ArchivalHistoriesControllerTest < Test::Unit::TestCase
  fixtures :archival_histories, :users

  def setup
    @controller = ArchivalHistoriesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    login_as(:admin)
  end

  def test_should_get_index    
    get :index
    assert_response :success
    assert assigns(:archival_histories)
  end
  
  def test_index_for_atom
    accept('application/atom+xml')
    get :index
    assert_template 'atom'
  end
end
