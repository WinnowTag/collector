# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please visit http://www.peerworks.org/contact for further information.
module ApplicationHelper
  def tab_selected(controller, action = nil)
    "selected" if controller_name == controller and (action.nil? or action_name == action)
  end
  
  def show_flash_messages
    javascript = [:notice, :warning, :error].map do |name|
      "Message.add('#{name}', #{flash[name].to_json});" unless flash[name].blank?
    end.join    
    javascript_tag(javascript) unless javascript.blank?
  end
  
  def search_field_tag(name, value = nil, options = {})
    options[:clear] ||= {}
    options[:placeholder] ||= "Search..."
    content_tag :div, 
      content_tag(:span, nil, :class => "sbox_l") +      
      tag(:input, :type => "search", :name => name, :id => name, :value =>  value, :results => 5, :placeholder => options[:placeholder], :autosave => name) +
      content_tag(:span, nil, :class => "sbox_r srch_clear"),
      :class => "applesearch clearfix"
  end
  
  def bookmarklet_js
    "javascript:window.location='#{feeds_url}?feed[url]='+window.location;"
  end

  def duration(summary)
    unless summary.completed_on.nil?
      seconds = (summary.completed_on - summary.created_on).to_i
      "#{seconds / 1.hour} hours, #{(seconds % 1.hour) / 1.minute} minutes"
    end
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
