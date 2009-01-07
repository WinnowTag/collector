Story: Atom Client Access
  As another system
  I want to be able to access feeds and items using atom
  So that I can cache feeds and items in my own format
  
  Scenario: Accessing the service description
    Given existing feeds in the system    
    When I fetch the service document    
    Then the document should have a workspace
      And  the workspace should have a title
      And  the workspace should have a collection for each feed
      And  the collections should have titles for each of the feeds
  
  Scenario: Accessing a feed
    Given a feed in the system
    When I fetch the service document
      And  I fetch the feed for the first collection
    Then the feed contains the items
      And it contains the title
      And the id is a uuid urn
  
  Scenario: Accessing an item for a feed
    Given a feed in the system
      And an item in the feed
    When I fetch the service document
      And I fetch the feed for the first collection
      And I get the first feed item entry
    Then it contains the title        
      And the id is a uuid urn
