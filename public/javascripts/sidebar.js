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

var Sidebar = Class.create({
  initialize: function(url, parameters, onLoad) {
    this.sidebar = $('sidebar');
    this.sidebar_control = $('sidebar_control');
    this.toggleListener = this.toggle.bind(this);
    
    if(Cookie.get("sidebar_width")) {
      this.sidebar.style.width = Cookie.get("sidebar_width") + 'px';
    }
    
    if(Cookie.get("show_sidebar") != false) {
      this.sidebar_control.addClassName("open")
      this.enableResize();
    } else {
      this.sidebar.hide();
    }
    
    this.enableToggle();
    this.load(url, parameters, onLoad);
  },
  
  enableToggle: function() {
    (function() { 
      this.sidebar_control.observe("click", this.toggleListener);
    }.bind(this)).delay(0.1);
  },
  
  disableToggle: function() {
    this.sidebar_control.stopObserving("click", this.toggleListener);
  },
  
  toggle: function() {
    this.sidebar.toggle();
    this.sidebar_control.toggleClassName("open")
    Cookie.set("show_sidebar", this.sidebar.visible(), 365);

    if(this.sidebar.visible()) {
      this.enableResize();
    } else {
      this.disableResize();
    }

    Content.instance.resizeWidth();
  },
  
  enableResize: function() {
    this.sidebar_control._draggable = new Draggable(this.sidebar_control, {constraint: 'horizontal', 
      change: this.resize.bind(this), 
      onStart: function() {
        this.sidebar_control.setStyle({backgroundColor: "#e1e1e1"});
        this.disableToggle();
      }.bind(this), 
      onEnd: function() {
        this.sidebar_control.setStyle({backgroundColor: ""});
        this.resize();
        this.enableToggle();
      }.bind(this)});
  },
  
  disableResize: function() {
    this.sidebar_control._draggable.destroy();
  },
  
  resize: function() {
    var sidebar_width = this.sidebar_control.cumulativeOffset().first() - 1;
    this.sidebar.style.width = sidebar_width + 'px';
    this.sidebar_control.style.left = 0;

    Cookie.set("sidebar_width", sidebar_width, 365);
    Content.instance.resizeWidth();
  },
  
  load: function(url, parameters, onComplete) {
    this.sidebar.addClassName("loading");

    new Ajax.Updater(this.sidebar, url, { method: 'get', evalScripts: true, parameters: parameters,
      onComplete: function() {
        this.sidebar.removeClassName("loading");
        onComplete();
      }.bind(this)
    });
  }
});