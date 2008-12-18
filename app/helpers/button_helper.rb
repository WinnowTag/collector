module ButtonHelper
  def rounded_button_link(name, options = {}, html_options = {})
    html_options[:class] = CssClass.new(html_options[:class], "button", :selected => html_options[:selected])
    if icon = html_options.delete(:icon)
      link_to(content_tag(:span, name, :class => "icon #{icon}"), options, html_options)
    else
      link_to(name, options, html_options)
    end
  end
  
  def rounded_button_link_to_remote(name, options = {}, html_options = {})
    html_options[:class] = CssClass.new(html_options[:class], "button", :selected => html_options[:selected])
    if icon = html_options.delete(:icon)
      link_to_remote(content_tag(:span, name, :class => "icon #{icon}"), options, html_options)
    else
      link_to_remote(name, options, html_options)
    end
  end

  def rounded_button_function(name, function, html_options = {}, &block)
    html_options[:class] = CssClass.new(html_options[:class], "button", :selected => html_options[:selected])
    if icon = html_options.delete(:icon)
      link_to_function(content_tag(:span, name, :class => "icon #{icon}"), function, html_options, &block)
    else
      link_to_function(name, function, html_options, &block)
    end
  end
  
  class CssClass < Array
    def initialize(*args)
      conditional_classes = args.extract_options!
      push(*args.join(" ").split(/\s+/))
      conditional_classes.each { |clazz, conditional| push clazz if conditional}
    end
    
    def to_s
      join(" ")
    end
  end
end
