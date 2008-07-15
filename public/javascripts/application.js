// Copyright (c) 2008 The Kaphan Foundation
//
// Possession of a copy of this file grants no permission or license
// to use, modify, or create derivate works.
// Please visit http://www.peerworks.org/contact for further information.
function enable_control(control) {
	$(control).removeClassName("disabled");
}

function disable_control(control) {
	$(control).addClassName("disabled");
}

var errorTimeout = null;
var ErrorMessage = Class.create();
ErrorMessage.prototype = {
	initialize: function(message) {
		if (errorTimeout) {
			clearTimeout(errorTimeout);
		}
		this.error_message = $('error_message');
		this.error_message.update(message);
		this.error_message.show();
		new Effect.Fade(this.error_message, {duration: 4});
		//errorTimeout = setTimeout(function(){new Effect.Fade(this.error_message);}.bind(this), 3000);
	}	
};

/** Ajax Responders to Handle time outs of Ajax requests */
Ajax.Responders.register({
	onCreate: function(request) {
		request.timeoutId = window.setTimeout(function() {
			var state = Ajax.Request.Events[request.transport.readyState];
			
			if (!['Uninitialized', 'Complete'].include(state)) {
				// disable the standard Prototype state change handle to avoid
				// confusion between timeouts and exceptions
				request.transport.onreadystatechange = Prototype.emptyFunction;
				request.transport.abort();
				
				if (request.options.onTimeout) {
					request.options.onTimeout(request.transport, request.json);
				} else {
					new ErrorMessage("Ajax request timed out. This should be handled by adding a onTimeout function to the request.");
				}
				
				if (request.options.onComplete && !(request instanceof Ajax.Updater)) {
					request.options.onComplete(request.transport, request.json);
				}
			}
		}, 10000);
	},
	onComplete: function(request) {
		if (request.timeoutId) {
			clearTimeout(request.timeoutId)
		}
	}
});