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

describe "headers" do
  it "all ruby files should have the kaphan foundation header" do
    vendor = %w[
      app/helpers/button_helper.rb
      db/schema.rb 
      features/support/env.rb features/step_definitions/webrat_steps.rb
      lib/authenticated_system.rb lib/authenticated_test_helper.rb lib/mongrel_health_check_handler.rb 
      lib/tasks/rspec.rake lib/tasks/cucumber.rake
    ]
    
    (Dir["{app,lib,db,profiling,spec,features}/**/*.{rb,rake}"] - vendor).each do |filename|
      filename.should have_ruby_kaphan_header
    end
  end
  
  it "all javascript files should have the kaphan foundation header" do
    vendor = %w[
      public/javascripts/controls.js public/javascripts/dragdrop.js public/javascripts/effects.js public/javascripts/prototype.js
      public/javascripts/slider.js public/javascripts/unittest.js public/javascripts/all.js public/javascripts/common.js
      public/javascripts/locales.js
    ]
    
    (Dir["public/javascripts/**/*.js"] - vendor).each do |filename|
      filename.should have_javascript_kaphan_header
    end
  end
  
  it "all stylesheets files should have the kaphan foundation header" do
    vendor = %w[
      public/stylesheets/all.css
      public/stylesheets/button.css public/stylesheets/defaults.css
    ]
    
    (Dir["public/stylesheets/**/*.css"] - vendor).each do |filename|
      filename.should have_stylesheet_kaphan_header
    end
  end
end
