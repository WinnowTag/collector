require File.dirname(__FILE__) + '/test_helper'

require 'cv/cross_validation'
require 'mocha'


class CrossValidationTest < Test::Unit::TestCase
  def test_true; assert true; end
  
  
  def _test_user_find_called_once
    User.expects(:find).with(:all).returns([]).times(1)
    cv = CrossValidation.new
    cv.execute('/tmp', File.open('/dev/null', 'w'))
  end
  
  def _test_training_occurences_for_each_feed_item
    tag1 = Tag.find_or_create_by_name('tag1')
    user = User.new
    user.stubs(:id).returns(1)
    user.stubs(:tags).returns([tag1])
    User.expects(:find).returns([user])
    
    taggings = []
    
    classifier = mock()
    classifier.expects(:score).returns(:true_positive).times(20)
    classifier.expects(:clear_training_data).times(2)
    classifier.expects(:trained_for?).returns(true).times(20)
    classifier.expects(:tokens).returns(%w(a b c)).times(2)
    classifier.expects(:train_count).returns(1).times(2)
    classifier.expects(:unique_token_count).returns(1).times(2)
    classifier.expects(:token_count).returns(1).times(2)
    
    classifier_class = mock()
    classifier_class.stubs(:new).returns(classifier).times(2)
    
    FeedItem.expects(:find).with(:all, {:select => 'distinct feed_items.id', 
                                        :joins => 'LEFT JOIN taggings on feed_items.id = taggings.taggable_id',
                                        :conditions => "taggings.tagger_type = 'User' and taggings.tagger_id = 1 and taggings.deleted_at is null",
                                        :limit => nil}).returns((1..20).to_a.map do |id| 
      fi = FeedItem.new
      fi.stubs(:id).returns(id); 
      mock_content = stub(:content_encoded => 'blahblahblah')
      fi.stubs(:content).returns(mock_content)
      FeedItem.stubs(:find).with(id).returns(fi)
      
      mock_tagging = Tagging.new
      mock_tagging.stubs(:tag).returns(tag1)
      mock_tagging.stubs(:taggable_id).returns(id)
      mock_tagging.stubs(:taggable).returns(fi)
      taggings << mock_tagging

      fi
    end)
    
    Tagging.stubs(:find).returns(taggings)
    taggings.each do |tagging|
      classifier.expects(:train).with(tagging, tagging.taggable).times(1)
    end
            
    (1..20).to_a.each do |id|
      classifier.expects(:guess).with(FeedItem.find(id), {}).returns(tag1 => 1).times(1)
    end
        
    cv = CrossValidation.new :classifier_class => classifier_class, :folds => 2
    cv.execute('/tmp', File.open('/dev/null', 'w'))
  end
  
  def _test_cross_validation_ignores_non_classified_tags_for_guessing
    seen = Tag.find_or_create_by_name('seen')
    user = User.new
    user.stubs(:id).returns(1)
    user.stubs(:tags).returns([seen])
    User.expects(:find).returns([user])
    
    fi = FeedItem.new
    fi.stubs(:id).returns(1); 
    mock_content = stub(:content_encoded => 'blahblahblah')
    fi.stubs(:content).returns(mock_content)
    FeedItem.stubs(:find).with(1).returns(fi)
    FeedItem.stubs(:find).with(:all, {:select => 'distinct feed_items.id', 
                                        :joins => 'LEFT JOIN taggings on feed_items.id = taggings.taggable_id',
                                        :conditions => "taggings.tagger_type = 'User' and taggings.tagger_id = 1 and taggings.deleted_at is null",
                                        :limit => nil}).returns([fi])
        
    classifier = mock()
    classifier.expects(:guess).times(1).returns({})
    classifier.expects(:score).times(0).returns(:true_positive)
    classifier.expects(:clear_training_data).times(2)
    classifier.expects(:tokens).returns(%w(a b c)).times(2)
    classifier.expects(:train_count).returns(1).times(2)
    classifier.expects(:unique_token_count).returns(1).times(2)
    classifier.expects(:token_count).returns(1).times(2)

    classifier_class = mock()
    classifier_class.stubs(:new).returns(classifier).times(2)
    
    cv = CrossValidation.new :classifier_class => classifier_class, :folds => 2, :tags_to_ignore => ['seen']
    cv.execute('/tmp', File.open('/dev/null', 'w'))
  end
end
