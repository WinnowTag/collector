-- This creates the trigger for inserting item ids into the 
-- unread_items table of a winnow instance whenever a new item
-- inserted into the feed items table.
--
-- There are limitations in MySQL's trigger support that affect this
-- trigger:
--
--  * Firstly a trigger must belong to the same database as the table
--    that activates it.  This forces the trigger to live in the collector
--    database.
--  * You can ony have on trigger to trigger time per table. This means
--    that only one trigger can fire AFTER INSERT on the feed_items table
--    so the updates to all instances of winnow must occur in the one trigger.
--  * The user that creates and executes the trigger must be have the SUPER
--    privilege. 
--    
--    These leaves us with the less than ideal situation where we need a
--    single trigger that is activated by a table in the collector schema and
--    inserts into tables in each of the winnow instance schemas and is owned
--    and executed as a super user.
--
-- To create this trigger, run it as root in the collector schema, replacing
-- the insert statement with an identical statement for each winnow schema.
--

DROP TRIGGER IF EXISTS unread_items_inserter;

DELIMITER |

CREATE TRIGGER unread_items_inserter AFTER INSERT ON feed_items
  FOR EACH ROW BEGIN
    INSERT IGNORE INTO alpha.unread_items (user_id, feed_item_id, created_on)
      SELECT id, NEW.id, UTC_TIMESTAMP() FROM alpha.users;
    INSERT IGNORE INTO trunk.unread_items (user_id, feed_item_id, created_on)
      SELECT id, NEW.id, UTC_TIMESTAMP() FROM trunk.users;
    INSERT IGNORE INTO seangeo.unread_items (user_id, feed_item_id, created_on)
      SELECT id, NEW.id, UTC_TIMESTAMP() FROM seangeo.users;
    INSERT IGNORE INTO mh.unread_items (user_id, feed_item_id, created_on)
      SELECT id, NEW.id, UTC_TIMESTAMP() FROM mh.users;
  END;
|

DELIMITER ;
