# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

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