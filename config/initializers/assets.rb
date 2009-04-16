ActionView::Helpers::AssetTagHelper.register_javascript_expansion :winnow => [
  "slider", "element", "cookies", "apple_search", "bias_slider", "timeout", "messages", 
  "labeled_input", "scroll", "classification", "item_browser", "feed_items_item_browser", 
  "tags_item_browser", "item", "sidebar", "content", "pagination"
]

ActionView::Helpers::AssetTagHelper.register_stylesheet_expansion :winnow => [
  "defaults", "button", "winnow", "tables", "slider", "scaffold"
]
