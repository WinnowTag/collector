# Copyright (c) 2005 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#
# application_helper.rb

# Methods added to this helper will be available to all templates in the application.

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
    value.gsub(/&lt;/,   "<"). 
          gsub(/&gt;/,   ">"). 
          gsub(/&quot;/, '"'). 
          gsub(/&apos;/, "'"). 
          gsub(/&amp;/,  "&") 
  end
  
  # Permit methods in the ApplicationController to be called from views.

  
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

  def appendable_url_for(options = {})
    url = url_for(options)
    
    if url =~ /.*\?.*/
      url += '&'
    else
      url += '?'
    end
  end

  def pagination_links(paginator, options = {}, html_options = {})
    options = options.merge :link_to_current_page => true
    options[:params] ||= {}
    
    pagination_links_each(paginator, options) do |page|
      if page == paginator.current_page.number
        content_tag('span', page, :class => 'current_page')
      else
        content_tag('span', link_to(page, options[:params].merge(:page => page), html_options))
      end
    end
  end
      
  def format_date(date, when_nil = "Never")
    if date.nil?
      when_nil
    else
      if current_user && current_user.tz
        date = current_user.tz.utc_to_local(date)
      end
      date.to_formatted_s(:short)
    end
  end  
end
