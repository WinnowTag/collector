Story: Atom Client Access

  As another system
  I want to be able to access feeds and items using atom
  So that I can cache feeds and items in my own format
  
  Scenario: Accessing the service description

    Given existing feeds in the system    
    And a base url
    
    When I fetch the service document    
    
    Then the document should have a workspace
    And  the workspace should have a title
    And  the workspace should have a collection for each feed
    And  the collections should have titles for each of the feeds
  
  Scenario: Accessing a feed
    Given feed 1 in the system
    And a base url
    
    When I fetch the service document
    And  I fetch the feed for the first collection
    
    Then the feed contains the items
    And  it contains the title
    And  the id is a uuid urn
    And  fetching self returns an Atom::Feed
  
  Scenario: Accessing an item for a feed
    Given feed 1 in the system
    And a base url
    And item 1 of the feed
    
    When I fetch the service document
    And I fetch the feed for the first collection
    And item 1 of the feed document
        
    Then  it contains the title        
    And the id is a uuid urn