# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
RAILS_ENV = 'production'
require File.join(File.dirname(__FILE__), '../config/environment')
require 'ruby-prof'
require 'action_controller/integration'

app = ActionController::Integration::Session.new
app.post '/account/login', :login => 'seangeo', :password => 'password'
app.get '/feed_items/index/0.js?tag_filter=all'

result = RubyProf.profile do
  app.get '/feed_items/index/0.js?tag_filter=all'
end

exit(1, "Error") if app.status != 200

# Print a graph profile to text
printer = RubyProf::GraphHtmlPrinter.new(result)
printer.print(STDOUT, 10)


