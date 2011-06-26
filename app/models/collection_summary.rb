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

class CollectionSummary < ActiveRecord::Base
  has_many :collection_errors
  has_many :collection_jobs, :order => "updated_at DESC"

  def self.search(options = {})
    order = case options[:order]
    when "item_count", "created_on", "completed_on"
      "collection_summaries.#{options[:order]}"
    when "errors_count"
      "(SELECT COUNT(*) FROM collection_errors WHERE collection_errors.collection_summary_id = collection_summaries.id)"
    when "duration"
      "(collection_summaries.completed_on - collection_summaries.created_on)"
    else
      options[:direction] = "desc"
      "collection_summaries.created_on"
    end
  
    case options[:direction]
    when "asc", "desc"
      order = "#{order} #{options[:direction].upcase}"
    end
  
    find(:all, :order => order, :limit => options[:limit], :offset => options[:offset])
  end
  
  def duration
    unless completed_on.nil?
      seconds = (completed_on - created_on).to_i
      minutes = (seconds % 1.hour) / 1.minute
      hours = seconds / 1.hour
      if hours > 0 && minutes > 0
        "#{hours}:#{'%.2d' % minutes} hours"
      elsif hours > 0
        "#{hours} hours"
      elsif minutes > 0
        "#{minutes} minutes"
      end
      
    end
  end
  
  def failed?
    !self.fatal_error_type.nil?
  end
  
  def status
    if failed?
      "failed"
    end
  end
  
  def increment_item_count(i)
    self.update_attribute(:item_count, self.item_count + i)
  end
  
  def job_completed!
    if collection_jobs.pending.count == 0
      self.completed_on = Time.now.getutc
      self.save
    end
  end
end
