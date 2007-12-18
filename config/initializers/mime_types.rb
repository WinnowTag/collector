Mime::Type.register "text/x-opml", :opml

ActionController::Base.param_parsers[Mime::Type.lookup("text/x-opml")] = Proc.new {|body| {:opml => Opml.parse(body)} }
   