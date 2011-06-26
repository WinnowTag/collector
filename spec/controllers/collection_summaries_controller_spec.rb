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
