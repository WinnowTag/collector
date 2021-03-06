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


/* Available Callbacks (in lifecycle order)
 *  - onStarted
 *  - onStartProgressUpdater
 *  - onProgressUpdated
 *  - onCancelled
 *  - onFinished
 */
var Classification = Class.create({
  initialize: function(classifier_url, has_changed_tags, options) {
    Classification.instance = this;
    
    this.classifier_url = classifier_url;
    this.has_changed_tags = has_changed_tags;
    
    this.classification_button = $('classification_button');
    this.cancel_classification_button = $('cancel_classification_button');
    this.classification_progress = $('classification_progress');
    this.progress_bar = $('progress_bar');
    this.progress_title = $('progress_title');
    
    this.classification_button.observe("click", this.start.bind(this))
    this.cancel_classification_button.observe("click", this.cancel.bind(this))
    
    this.options = {
      onStarted: function(c) {     
        this.classification_button.hide();
        this.cancel_classification_button.show();

        this.progress_bar.setStyle({width: '0%'});
        this.progress_title.update(I18n.t("winnow.javascript.classifier.progress_bar.start"));
        this.classification_progress.show();

        Content.instance.resizeHeight();
      }.bind(this),
      
      onStartProgressUpdater: function() {
        this.classifier_items_loaded = 0;
      }.bind(this),
      
      onProgressUpdated: function(progress) {
        this.progress_bar.setStyle({width: progress.progress + '%'});      
      }.bind(this),
      
      onCancelled: function() {
        this.classification_progress.hide();
        this.progress_bar.setStyle({width: '0%'});
        this.progress_title.update(I18n.t("winnow.javascript.classifier.progress_bar.cancel"));
        
        this.cancel_classification_button.hide();
        this.classification_button.show();

        Content.instance.resizeHeight();
      }.bind(this),
      
      onFinished: function() {
        this.classification_progress.hide();
        this.notify("Cancelled")
        this.progress_title.update(I18n.t("winnow.javascript.classifier.progress_bar.finish"));
        this.disableClassification();
        if(confirm(I18n.t("winnow.javascript.classifier.progress_bar.reload"))) {
          itemBrowser.reload();
        }
        $$(".filter_list .tag").each(function(tag) {
          new Ajax.Request("/tags/" + tag.getAttribute('id').match(/\d+/).first() + "/information", { method: 'get',
            onComplete: function(response) {
              tag.title = response.responseText;
            }
          });
        });
      }.bind(this)
    }
    
    if(!this.has_changed_tags) {
      this.disableClassification();
    }
  },
  
  disableClassification: function() {
    this.classification_button.addClassName("disabled");
  },
  
  enableClassification: function() {
    this.classification_button.removeClassName("disabled");
  },
  
  /* puct_confirm == true means that that user has confirmed that they want to 
   * classify some potentially undertrained tags.
   */
  start: function(puct_confirm) {
    if(this.classification_button.hasClassName("disabled")) { return; }
    
    parameters = null;
    if (puct_confirm) {
      parameters = {puct_confirm: 'true'};
    }  
          
    new Ajax.Request(this.classifier_url + '/classify', {
      parameters: parameters,
      evalScripts: true,
      onSuccess: function() {
        this.notify('Started');
        this.startProgressUpdater();  
      }.bind(this),
      onFailure: function(transport) {
        if(transport.responseJSON == I18n.t("winnow.javascript.classifier.progress_bar.running")) {
          this.notify("Started");
          this.startProgressUpdater();
        } else {
          Message.add('error', transport.responseJSON);
          this.notify('Cancelled');  
        }
      }.bind(this),
      onTimeout: function() {
        this.notify("Cancelled");
        Message.add('error', I18n.t("winnow.javascript.errors.classifier.timeout"));
      }.bind(this),
      on412: function(response) {
        this.notify('Cancelled');
        if (response.responseJSON) {
          var tags = response.responseJSON.map(function(t) { return "'" + t + "'";}).sort();
          var tag_names = tags.first();
        
          if (tags.size() > 1) {
            var last = tags.last();
            tag_names = tags.slice(0, tags.size() - 1).join(", ") + ' ' + I18n.t("winnow.javascript.general.and") + ' ' + last;
          } 
        
          new ConfirmationMessage(I18n.t("winnow.javascript.classifier.confirm_few_positives", { tag_names: tag_names, count: tag_names.length }), function() {
            this.start(true);
          }.bind(this));
        }
      }.bind(this)
    });
  },
  
  cancel: function() {
    this.progressUpdater.stop();
    this.reset();
        
    new Ajax.Request(this.classifier_url + '/cancel?no_redirect=true', {
      onComplete: function() {
        this.notify('Cancelled');
      }.bind(this),
      onFailure: function(transport) {
        Message.add('error', transport.responseText);
        this.notify('Cancelled');
      }
    });    
  },
  
  startProgressUpdater: function() {
    this.notify('StartProgressUpdater');
    this.progressUpdater = new PeriodicalExecuter(function(executer) {
      if (!this.loading) {
        this.loading = true;
        new Ajax.Request(this.classifier_url + '/status', {
          onComplete: function(transport, json) {          
            this.loading = false;
            if (!json || json.progress >= 100) {
              executer.stop();
              this.notify('Finished');
            }
          }.bind(this),
          onSuccess: function(transport, json) {
            if (this.options.onProgressUpdated) {
              this.options.onProgressUpdated(json);
            }
          }.bind(this),
          onFailure: function(transport) {
            this.notify("Cancelled");
            executer.stop();
            Message.add('error', transport.responseJSON);
          }.bind(this),
          onTimeout: function() {
            executer.stop();
            this.notify("Cancelled");
            Message.add('error', I18n.t("winnow.javascript.errors.classifier.timeout"));
          }.bind(this)
        });
      }
    }.bind(this), 2);
  },

  notify: function(event) {
    if (this.options['on' + event]) {
      this.options['on' + event](this);
    }
  }
});
