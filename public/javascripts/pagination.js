// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
var Pagination = Class.create({
  initialize: function(pagination) {
    pagination.select("a").each(function(link) {
      link.observe("click", function(event) {
        event.stop();
        new Ajax.Request(link.getAttribute("href"), {
          method: 'get', requestHeaders: { Accept: 'application/json' },
          onComplete: function(request) {
            var data = request.responseJSON;

            var new_pagination = Element.fromHTML(data.pagination)
            pagination.replace(new_pagination);
            new Pagination(new_pagination);
            
            console.log(data.records);
            console.log(pagination.getAttribute("update"));
            console.log($(pagination.getAttribute("update")));
            $(pagination.getAttribute("update")).update(data.records);
          }
        });
      });
    });
  }
});

document.observe('dom:loaded', function() {
  $$(".pagination").each(function(element) {
    new Pagination(element);
  });
});
