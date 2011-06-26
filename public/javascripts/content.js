// General info: http://doc.winnowtag.org/open-source
// Source code repository: http://github.com/winnowtag
// Questions and feedback: contact@winnowtag.org
//
// Copyright (c) 2007-2011 The Kaphan Foundation
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

var Content = Class.create({
  initialize: function() {
    this.body            = document.body;
    this.container       = $("container");
    this.content         = $("content");
    this.footer          = $("footer");
    this.messages        = $("messages");
    this.sidebar         = $("sidebar");
    this.sidebar_control = $("sidebar_control");
    
    Event.observe(window, 'resize', this.resize.bind(this));
		setInterval(this.checkFontSize.bind(this), 500);
  },
  
  checkFontSize: function() {
		var currentFontSize = window.getComputedStyle(document.documentElement, null).fontSize;
		if(!this.lastFontSize || currentFontSize != this.lastFontSize) {
			this.lastFontSize = currentFontSize;
      this.resize();
		}
  },
  
  resize: function() {
    this.resizeWidth();
    this.resizeHeight();
    this.resizeSidebar();
  },
  
  resizeHeight: function() {
    this.content.style.height = this.contentHeight() + 'px';
  },
  
  resizeWidth: function() {
    this.container.style.width = this.contentWidth() + 'px';
  },
  
  resizeSidebar: function() {
    if(this.sidebar) {
      this.sidebar.style.height = this.sidebarHeight() + 'px';
    }
    if(this.sidebar_control) {
      this.sidebar_control.style.height = this.sidebarControlHeight() + 'px';
    }
  },
  
  contentHeight: function() {
    var body_height = this.body.getHeight();
    var top_of_content = this.content.offsetTop;
    var content_padding = parseInt(this.content.getStyle("padding-top")) + parseInt(this.content.getStyle("padding-bottom"));
    var footer_height = this.footer ? this.footer.getHeight() : 0;

    return body_height - top_of_content - content_padding - footer_height;
  },
  
  contentWidth: function() {
    var body_width = this.body.getWidth();

    var sidebar_width = 0;
    if(this.sidebar && this.sidebar.visible()) {
      sidebar_width = this.sidebar.getWidth();
    }
    
    var sidebar_control_width = 0, sidebar_control_margin = 0;
    if(this.sidebar_control) {
      sidebar_control_width = this.sidebar_control.getWidth();
      sidebar_control_margin = parseInt(this.sidebar_control.getStyle("margin-left")) + parseInt(this.sidebar_control.getStyle("margin-right"));
    }
    
    var container_padding = parseInt(this.container.getStyle("padding-left"));

    var extra = 0;
    if(Prototype.Browser.Gecko) {
      // sometimes firefox is just a little off, this keeps the content visible
      extra = 0.25;
    }

    return body_width - sidebar_width - sidebar_control_width - sidebar_control_margin - container_padding - extra;
  },
  
  sidebarHeight: function() {
    var body_height = this.body.getHeight();
    var top_of_sidebar = this.sidebar.offsetTop;
    
    return body_height - top_of_sidebar;
  },
  
  sidebarControlHeight: function() {
    var body_height = this.body.getHeight();
    var top_of_sidebar_control = this.sidebar_control.offsetTop;

    return body_height - top_of_sidebar_control;
  }
});

Content.setup = function() {
  Content.instance = new Content();
}
