# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
module CollectionSummariesHelper
  include FeedsHelper
  
  def atom_summary(cs)
    if cs.failed?
      t('collector.collection_summary.atom.failed', :image => image_tag('error.png'), :when => format_date(cs.completed_on), :error_type => cs.fatal_error_type) + details(cs)
    elsif cs.completed_on
      t('collector.collection_summary.atom.completed', :image => image_tag('notice.png'), :when => format_date(cs.completed_on)) + details(cs)
    else
      t('collector.collection_summary.atom.started', :image => image_tag('hourglass.png'), :when => format_date(cs.created_on))
    end
  end

  def details(cs)
    "<br/><br/>" +
    t('collector.collection_summary.atom.items', :image => image_tag('notice.png'), :count => cs.item_count) +
    t('collector.collection_summary.atom.collected', :duration => cs.duration) +
    t('collector.collection_summary.atom.errors', :count => cs.collection_errors.size) +
    "<br/><br/>\n"
  end
end
