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


// Base class for managing a list of items. More items are added to the list
// as the user scrolls down, eliminating the need for explicit paging. Sorting
// and filtering are also handled here.
var ItemBrowser = Class.create({
  initialize: function(name, container, options) {
    this.options = {
      controller: name,
      url: name,
      orders: {},
      modes: []
    };
    Object.extend(this.options, options || {});
    
    this.name = name;
    this.update_queue = [];
    this.loading = false;
    this.full = false;
    
    this.container = $(container);
    this.container.observe('scroll', this.updateItems.bind(this));
    
    this.order_control = $("order");
    this.direction_control = $("direction");

    this.initializeFilters();
  },

  updateItems: function() {
    if(this.full || this.loading) { return; }    
    var scroll_bottom = this.container.scrollHeight - this.container.scrollTop - this.container.getHeight();
    if(scroll_bottom <= 100) {
      this.loading = true;
      this.doUpdate({offset: this.numberOfItems().size()});
    }
  },
  
  numberOfItems: function() {
    return this.container.childElements().select(function(element) {
      return !element.match(".indicator") && !element.match(".empty");
    });
  },
    
  doUpdate: function(options) {
    this.showLoadingIndicator();
    
    new Ajax.Request(this.buildUpdateURL(options || {}), { 
      method: 'get', requestHeaders: { Accept: 'application/json' },
      onComplete: function(response) {
        var data = response.responseJSON;
        if(data.full) {
          this.full = true;
        }
        data.items.each(function(item) {
          this.insertItem(item.id, item.content);
        }.bind(this));
        
        this.updateEmptyMessage();
        this.hideLoadingIndicator();
        this.loading = false;
        this.updateFromQueue();
      }.bind(this)
    });  
  },

  buildUpdateURL: function(parameters) {
    return '/' + this.options.url + '?' + $H(this.filters).merge($H(parameters)).toQueryString();
  },
  
  insertItem: function(item_id, content) {
    this.container.insert(content);
  },
 
  updateEmptyMessage: function() {
    if(this.full && this.numberOfItems().size() == 0) {
      this.container.insert('<div class="empty" style="display:none">' + I18n.t("winnow.general.empty") + '</div>');
      var message = $$("#" + this.container.getAttribute("id") + " > .empty").first();
  
      var message_padding = parseInt(message.getStyle("padding-top")) + parseInt(message.getStyle("padding-bottom"));
      var footer_height = $('footer') ? $('footer').getHeight() : 0;
      var top = (this.container.getHeight() - message.getHeight() - message_padding) / 2;
      message.style.top = top + "px";
    
      var left = (this.container.getWidth() - message.getWidth()) / 2;
      message.style.left = left + "px";
  
      message.show();
    } else {
      var message = $$("#" + this.container.getAttribute("id") + " > .empty").first();
      if(message) {
        message.remove();
      }
    }
  },
  
  showLoadingIndicator: function() {
    this.container.insert('<div class="indicator" style="display:none">' + I18n.t("winnow.general.loading") + '</div>');
    var indicator = $$("#" + this.container.getAttribute("id") + " > .indicator").first();
  
    if(this.numberOfItems().size() == 0) {
      var indicator_padding = parseInt(indicator.getStyle("padding-top")) + parseInt(indicator.getStyle("padding-bottom"));
      var footer_height = $('footer') ? $('footer').getHeight() : 0;
      var top = (this.container.getHeight() - indicator.getHeight() - indicator_padding) / 2;
      indicator.style.top = top + "px";
    }
  
    var left = (this.container.getWidth() - indicator.getWidth()) / 2;
    indicator.style.left = left + "px";
    
    indicator.show();
  },
  
  hideLoadingIndicator: function() {
    var indicator = $$("#" + this.container.getAttribute("id") + " > .indicator").first();
    indicator.remove();
  },

  // Called at the end of a request to process more items in the update queue, if any.
  updateFromQueue: function() {
    if (this.update_queue.any()) {
      var next_action = this.update_queue.shift();
      next_action();
    }
  },
  
  // Clear the list of items and load it. Called when changing sort order or
  // adding/removing filters. Queues request if it's already in the act of
  // loading; otherwise it executes request immediately.
  reload: function() {
    var clearAndUpdate = function() {
      this.loading = true;
      this.clear();
      this.doUpdate();
    }.bind(this);
    
    if (this.loading) {
      this.update_queue.push(clearAndUpdate);
    } else {
      clearAndUpdate();
    }
  },

  clear: function() {
    this.full = false;
    this.container.update('');
  },
  
  modes: function() {
    return this.options.modes;
  },
  
  defaultMode: function() {
    return this.options.modes.first();
  },
  
  orders: function() {
    return (this.options.orders.asc || []).concat(this.options.orders.desc || []);
  },
  
  defaultOrder: function() {
    return this.options.orders["default"];
  },
  
  defaultDirection: function(order) {
    order = order || this.defaultOrder();
    
    if(this.options.orders.desc.include(order)) {
      return "desc";
    } else {
      return "asc";
    }
  },
  
  setOrder: function(order) {
    if(this.filters.order == order) {
      this.filters.direction = (this.filters.direction == "asc" ? "desc" : "asc");
    } else {
      this.filters.order = order;
      this.filters.direction = this.defaultDirection(order);
    }
    
    this.saveFilters();
    this.styleOrders();
    this.reload();
  },

  toggleDirection: function() {
    this.filters.direction = (this.filters.direction == "asc" ? "desc" : "asc");
    this.saveFilters();
    this.styleOrders();
    this.reload();
  },
  
  saveFilters: function() {
    // Remove empty values
    var filters_hash = $H(this.filters);
    filters_hash.each(function(key_value) {
      var key = key_value[0];
      var value = key_value[1];
      if(value == null || Object.isUndefined(value) || (typeof(value) == 'string' && value.blank())) {
        filters_hash.unset(key);
      }
    });
    this.filters = filters_hash.toQueryString().toQueryParams();
    
    location.hash = "#" + $H(this.filters).toQueryString();

    // Do not persist the text_filter
    var filters_to_save = $H(this.filters);
    filters_to_save.unset("text_filter");
    
    Cookie.set(this.name + "_filters", filters_to_save.toQueryString(), 365);
  },
  
  // Marks the appropriate mode filter (all, unread, trained) for items as selected.
  styleModes: function() {
    if(this.filters.mode) {
      this.modes().without(this.filters.mode).each(function(mode) {
        $("mode_" + mode).removeClassName("selected")
      });
    
      var mode_control = $("mode_" + this.filters.mode);
      if(mode_control) {
        mode_control.addClassName("selected");
      }
    } else if(this.defaultMode()) {
      this.modes().without(this.defaultMode()).each(function(mode) {
        $("mode_" + mode).removeClassName("selected")
      });
    
      var mode_control = $("mode_" + this.defaultMode());
      if(mode_control) {
        mode_control.addClassName("selected");
      }
    }
  },
  
  // Selects the appropriate option from the list of possible sort orders and
  // sets the appropriate class on the Ascending/Descending toggle.
  styleOrders: function() {
    this.direction_control.removeClassName("asc");
    this.direction_control.removeClassName("desc");
  
    if(this.filters.order) {
      this.order_control.select("option").each(function(option, index) {
        if(option.value == this.filters.order) {
          this.order_control.selectedIndex = index;
        }
      }.bind(this));
      this.direction_control.addClassName(this.filters.direction);
    } else if(this.defaultOrder()) {
      this.order_control.select("option").each(function(option, index) {
        if(option.value == this.filters.order) {
          this.order_control.selectedIndex = index;
        }
      }.bind(this));
      this.direction_control.addClassName(this.defaultDirection());
    }
  },
  
  bindModeFiltersEvents: function() {
    this.modes().each(function(mode) {
      var mode_control = $("mode_" + mode);
      if(mode_control) {
        mode_control.observe("click", this.addFilters.bind(this, {mode: mode}));
      }
    }.bind(this));
  },

  bindOrderFilterEvents: function() {
    this.order_control.observe("change", function() {
      this.setOrder(this.order_control.value);
    }.bind(this));

    this.direction_control.observe("click", this.toggleDirection.bind(this));
  },

  bindTextFilterEvents: function() {
    var text_filter_form = $("text_filter_form");
    if(text_filter_form) {
      text_filter_form.observe("submit", function() {
        this.addFilters({text_filter: $F('text_filter')});
      }.bind(this));
    }
  },
  
  bindTextFilterClearEvents: function() {
    var text_filter = $("text_filter");
    if(text_filter) {
      var clear_button = text_filter.next(".srch_clear");
      if(clear_button) {
        clear_button.observe("click", function() {
          // TODO: don't do this if the button was not active
          this.addFilters({text_filter: null});
        }.bind(this));
      }
    }
  },

  initializeFilters: function() {
    this.bindModeFiltersEvents();
    this.bindOrderFilterEvents();
    this.bindTextFilterEvents();
    this.bindTextFilterClearEvents();

    this.filters = { order: this.defaultOrder(), direction: this.defaultDirection(), mode: this.defaultMode() };
    
    if(location.hash.gsub('#', '').blank() && Cookie.get(this.name + "_filters")) {
      this.setFilters(Cookie.get(this.name + "_filters").toQueryParams());
    } else {
      this.setFilters(location.hash.gsub('#', '').toQueryParams());
    }
  },

  setFilters: function(parameters) {
    this.addFilters(parameters);
  },
  
  addFilters: function(parameters) {
    var new_parameters = $H(this.filters).merge($H(parameters));
    this.filters = new_parameters.toQueryString().toQueryParams();
    
    this.saveFilters();    
    this.styleFilters();
    this.reload();
  },

  styleFilters: function() {
    this.styleModes();
    this.styleOrders();

    var text_filter = $("text_filter");
    if(text_filter) {
      if(this.filters.text_filter) {
        text_filter.value = this.filters.text_filter;
        text_filter.fire("applesearch:setup");
      } else {
        text_filter.value = "";
        text_filter.fire("applesearch:blur");
      }
    }
  }
});
