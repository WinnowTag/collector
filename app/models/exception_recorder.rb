# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module ExceptionRecorder
  def exception=(e)
    self.error_type = e.class.name
    self.error_message = e.message
  end
  alias_method :e=, :exception=
  
  def failed?
    [self.error_type, self.error_message].any?
  end
end