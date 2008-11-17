# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class AboutController < ApplicationController
  def index
    @about = `svn info #{__FILE__}`
    
    if @about =~ /Revision: ([\d]+)/
      @revision = $1
    end
    
    if @about =~ /http:\/\/svn.winnow.peerworks.org\/(.+)\/app\/controllers\/about_controller.rb/
      @repos = $1
    end
  end
  
  def help
  end
end
