# General info: http://doc.winnowtag.org/open-source
# Source code repository: http://github.com/winnowtag
# Questions and feedback: contact@winnowtag.org
#
# Copyright (c) 2007-2011 The Kaphan Foundation
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
