# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
class AboutController < ApplicationController
  def index
    # Capistrano now stores the revision in RAILS_ROOT/REVISION
    cap_rev_file = File.join(RAILS_ROOT, 'REVISION')

    if File.exists?(cap_rev_file)
      @revision = File.read(cap_rev_file)
    else
      @revision = `git rev-parse --short HEAD`.chomp
    end
  end
  
  def help
  end
end
