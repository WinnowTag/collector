# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module CollectionSummariesHelper
  include FeedsHelper
  
  def atom_summary(cs)
    summary = ""
    
    if cs.failed?
      summary += image_tag('error.png') + 
              " Collection aborted at #{format_date(cs.completed_on)} " +
              "due to #{cs.fatal_error_type}<br/><br/>"
    elsif cs.completed_on
      summary = image_tag('notice.png') + 
              " Collection completed at #{format_date(cs.completed_on)}. <br/><br/>"
    else
      summary = image_tag('hourglass.png') + " Collection started at #{format_date(cs.created_on)}"
    end

    if cs.failed? or cs.completed_on
      summary += image_tag('notice.png') + ' ' +
               pluralize(cs.item_count, "new item") +
               " collected in #{duration(cs)} with " +
               pluralize(cs.collection_errors.size, "collection error") + ".<br/><br/>\n"
    end
              
    summary
  end
end
