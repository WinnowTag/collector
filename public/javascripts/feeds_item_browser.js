// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var FeedsItemBrowser = Class.create(ItemBrowser, {
  initialize: function($super, name, container, options) {
    this.modes = ["all", "duplicates"];
    this.default_mode = "all";
    $super(name, container, options);
  },

  styleFilters: function($super) {
    $super();

    if(this.filters.mode) {
      this.modes.without(this.filters.mode).each(function(mode) {
        $("mode_" + mode).removeClassName("selected")
      });
    
      $("mode_" + this.filters.mode).addClassName("selected");
    } else {
      this.modes.without(this.default_mode).each(function(mode) {
        $("mode_" + mode).removeClassName("selected")
      });
    
      $("mode_" + this.default_mode).addClassName("selected");
    }
  },
  
  bindModeFiltersEvents: function() {
    this.modes.each(function(mode) {
      var mode_control = $("mode_" + mode);
      if(mode_control) {
        mode_control.observe("click", this.addFilters.bind(this, {mode: mode}));
      }
    }.bind(this));
  },
  
  initializeFilters: function($super) {
    $super();
    this.bindModeFiltersEvents();
  }
});
