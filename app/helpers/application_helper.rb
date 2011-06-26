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
