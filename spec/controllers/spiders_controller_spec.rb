 
require File.dirname(__FILE__) + "/../spec_helper.rb"

describe SpidersController do
  fixtures :users
    
  before(:each) do
    login_as(:admin)
  end

  it "should GET the index" do
    get :index
  end
end

