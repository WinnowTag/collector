# Copyright (c) 2007 The Kaphan Foundation
#
# Possession of a copy of this file grants no permission or license
# to use, modify, or create derivate works.
# Please contact info@peerworks.org for further information.
#

module Analysis
  RANDOM_BACKGROUND = '__random_background__'
  TAGS_TO_IGNORE = ['unwanted', 'seen', 'duplicate', 'missing entry', RANDOM_BACKGROUND, 'SHORT', /^\*.*/, /^_!not_.*/]
  NEGATIVE_POOL_PATTERN = '_!not_#{pool_name}'
  
  def create_classifier(tokenizer)
    classifier = Bayes::Classifier.new do |classifier|
      classifier.pools_to_ignore = TAGS_TO_IGNORE
      classifier.tokenizer = tokenizer
      classifier.background_pool_specs << Bayes::Classifier::PoolSpec.new do |spec|
        spec.name = "Negative Taggings"
        spec.description = "Pool to store user applied negative taggings"
        spec.pattern = NEGATIVE_POOL_PATTERN
      end
      classifier.background_pool_specs << Bayes::Classifier::PoolSpec.new do |spec|
        spec.name = "Random Background"
        spec.pattern = RANDOM_BACKGROUND
      end
    end
  end
  
  def pool_name_for(tagging)
    if tagging.strength == 1
      tagging.tag
    else
      "_!not_#{tagging.tag}"
    end
  end
end
