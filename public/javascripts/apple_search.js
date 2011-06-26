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

var AppleSearch = Class.create({
  initialize: function(element) {
    this.element = element;
    this.element.addClassName("non_safari");
    this.element.applesearch = this;

    this.text_input = element.down("input");
    this.text_input.observe("keyup", this.updateClearButton.bind(this));
    this.text_input.observe("focus", this.removePlaceholder.bind(this));
    this.text_input.observe("blur", function() {
      this.updateClearButton();
      this.insertPlaceholder();
    }.bind(this));
    this.text_input.observe("applesearch:blur", function() {
      this.updateClearButton();
      this.insertPlaceholder();
    }.bind(this));
    this.text_input.observe("applesearch:setup", function() {
      this.updateClearButton();
      this.removePlaceholder();
    }.bind(this));

    this.clear_button = element.down('.srch_clear');
    this.clear_button.observe("click", this.clear.bind(this));
    
    this.updateClearButton();
    this.insertPlaceholder();
  },

  updateClearButton: function() {
    if(this.text_input.value.length > 0) {
      this.clear_button.addClassName("clear_button");
    } else {
      this.clear_button.removeClassName("clear_button");
    }
  },
  
  clear: function () {
    this.text_input.value = "";
    this.updateClearButton();
    this.text_input.focus();
  },

  insertPlaceholder: function() {
    if(this.text_input.value == "") {
      this.text_input.addClassName("placeholder");
      this.text_input.value = this.text_input.getAttribute("placeholder");
    }
  },

  removePlaceholder: function() {
    if(this.text_input.value == this.text_input.getAttribute("placeholder")) {
      this.text_input.value = "";
    }
    this.text_input.removeClassName("placeholder");
  }
});

AppleSearch.setup = function() {
  if(navigator.userAgent.toLowerCase().indexOf('safari') >= 0) { return; }
  
  $$(".applesearch").each(function(element) {
    new AppleSearch(element);
  });
};
