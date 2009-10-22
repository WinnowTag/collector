# Copyright (c) 2008 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivative works.
# Please visit http://www.peerworks.org/contact for further information.
module ApplicationHelper
  def tab_selected(controller, *actions)
    "selected" if controller_name == controller and (actions.blank? or actions.include?(action_name))
  end
  
  def show_flash_messages
    javascript = [:notice, :warning, :error].map do |name|
      "Message.add('#{name}', #{flash[name].to_json});" unless flash[name].blank?
    end.join    
    javascript_tag(javascript) unless javascript.blank?
  end
  
  def search_field_tag(name, value = nil, options = {})
    options[:clear] ||= {}
    options[:placeholder] ||= t("collector.general.default_search_placeholder")
    content_tag :div, 
      content_tag(:span, nil, :class => "sbox_l") +      
      tag(:input, :type => "search", :name => name, :id => name, :value =>  value, :results => 5, :placeholder => options[:placeholder], :autosave => name) +
      content_tag(:span, nil, :class => "sbox_r srch_clear"),
      :class => "applesearch clearfix"
  end
  
  def format_date(date, when_nil = t("collector.general.never"))
    if date.nil?
      when_nil
    elsif date.is_a?(String)
      Time.parse(date).to_formatted_s(:short) rescue when_nil
    else
      date.to_formatted_s(:short)
    end
  end  
end
