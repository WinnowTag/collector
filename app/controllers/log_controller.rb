# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
class LogController < ApplicationController

  def collect
    @match = params[:match]
    # TODO: use regex instead
    if !@match.nil?
      if (@match[0] == '"')
        @match.chomp!('"')
        @match.reverse!
        @match.chomp!('"')
        @match.reverse!
      else (@match[0] == "'")
        @match.chomp!("'")
        @match.reverse!
        @match.chomp!("'")
        @match.reverse!
      end
    end
  end
end
