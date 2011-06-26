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

var BiasSlider = Class.create(Control.Slider, {
  initialize: function($super, handle, track, options) {
    $super(handle, track, options);
    this.initializeTicks();
  },
  setDisabled: function() {
    this.disabled = true;
    this.track.addClassName('disabled');    
  },
  setEnabled: function() {
    this.disabled = false;
    this.track.removeClassName('disabled');
  },
  sendUpdate: function(bias, tag_id) {
    new Ajax.Request("/tags/" + tag_id + "?tag[bias]=" + bias, {method: "PUT"});
  },
  initializeTicks: function() {
    var ticks = $H({0.9: "0_9", 1.0: "1_0", 1.1: "1_1", 1.2: "1_2", 1.3: "1_3"});
    ticks.each(function(key_value) {
      var key = key_value[0];
      var value = key_value[1];
      this.track.down("." + value).setStyle({left: this.translateToPx(key)});
      if(!this.disabled) {
        this.track.down("." + value).observe('mousedown', this.setValue.bind(this, key, 0));
      }
    }.bind(this));
  }
});

BiasSlider.sliders = {};