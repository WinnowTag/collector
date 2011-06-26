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

require File.dirname(__FILE__) + '/../../spec_helper'

describe '/service/index' do
  before(:each) do
    @feed1 = mock_model(Feed, valid_feed_attributes)
    @feed2 = mock_model(Feed, valid_feed_attributes)
    @feeds = [@feed1, @feed2]
    assigns[:feeds] = @feeds
  end
  
  it "should render an atom service document" do
    render '/service/index.atom.builder'
    response.should have_tag('service')
  end
  
  it "should define the app namespace on the service element" do
    render '/service/index.atom.builder'
    response.should have_tag("service[xmlns = '#{Atom::Pub::NAMESPACE}']")
  end
  
  it "should bind the atom namespace" do
    render '/service/index.atom.builder'
    response.body.should match(/xmlns:atom="#{Atom::NAMESPACE}"/)
  end
  
  it "should render a single workspace" do
    render '/service/index.atom.builder'
    response.should have_tag('service workspace')
  end
  
  it "should render a title for the workspace" do
    render '/service/index.atom.builder'
    response.body.should match(/<atom:title>Peerworks Collector<\/atom:title>/)   
  end
  
  it "should render a collection for each feed" do
    render '/service/index.atom.builder'
    response.should have_tag('service workspace') do |node|
      node.should have_tag('collection', 2)
    end      
  end
  
  it "should have hrefs for each feed" do
    render '/service/index.atom.builder'
    response.should have_tag('service workspace') do |node|      
      node.should have_tag("collection[href = '#{feed_url(@feed1)}.atom']")
      node.should have_tag("collection[href = '#{feed_url(@feed2)}.atom']")
    end
  end
  
  it "should have titles for each feed" do
    render '/service/index.atom.builder'
    response.body.should match(/<atom:title>#{@feed1.title}<\/atom:title>/)
    response.body.should match(/<atom:title>#{@feed2.title}<\/atom:title>/)
  end
  
  it "should have a single empty accept" do
    render '/service/index.atom.builder'
    response.should have_tag('accept', "")
    response.should_not have_tag('accept', /.+/)
  end
end