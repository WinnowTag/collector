Story: Feed Management
  As a User
  I want to add feeds
  So I can get content
  
  Scenario: Adding a feed
    Given no feeds
      And no item caches
      And I am a logged in user
    When I add the feed http://example.org
    Then I'm redirected to the feed
      And there is another feed in the system
      
  Scenario: Adding a feed to an item cache
      Given no feeds
        And 1 item cache
  			And I am a logged in user
      When I add the feed http://example.org
      Then I'm redirected to the feed
        And there is another feed in the system
        And the feed is published to the item cache
