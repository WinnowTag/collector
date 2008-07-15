# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
fork do
  [STDOUT,STDERR].each {|f| f.reopen '/dev/null', 'w' }
  exec('mongrel_rails start -e test -p 4000')
end
