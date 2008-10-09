# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module ApplicationHelper  
  def tab_link(name, url)
    link_to_unless_current(name, url) do |name|
      content_tag('span', name, :class => 'current')
    end
  end
  
  def duration(summary)
    unless summary.completed_on.nil?
      seconds = (summary.completed_on - summary.created_on).to_i
      "#{seconds / 1.hour} hours, #{(seconds % 1.hour) / 1.minute} minutes"
    end
  end
  
  def unescape(value)
    if value
      value.gsub(/&lt;/,   "<"). 
          gsub(/&gt;/,   ">"). 
          gsub(/&quot;/, '"'). 
          gsub(/&apos;/, "'"). 
          gsub(/&amp;/,  "&")
    end
  end
  
  def show_flash
    [:notice, :warning, :message, :error].map do |name|
      if flash[name]
        content_tag 'div', 
            image_tag("#{name}.png", :class => 'flash_icon', :size => '16x16', :alt => '') +
            flash[name].to_s + 
            link_to_function(
                    image_tag('cross.png',
                              :size => '11x11',
                              :alt => 'X',
                              :class => 'flash_icon'), 
                    "$('#{name}').hide();", 
                    :id => 'close_flash',
                    :title => 'Close message') , 
          :id => name.to_s
      end
    end.compact.join
  end

  def format_date(date, when_nil = "Never")
    if date.nil?
      when_nil
    elsif date.is_a?(String)
      Time.parse(date).to_formatted_s(:short) rescue when_nil
    else
      date.to_formatted_s(:short)
    end
  end  
end
