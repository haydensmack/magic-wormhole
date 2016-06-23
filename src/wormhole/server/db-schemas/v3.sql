
-- note: anything which isn't an boolean, integer, or human-readable unicode
-- string, (i.e. binary strings) will be stored as hex

CREATE TABLE `version`
(
 `version` INTEGER -- contains one row, set to 3
);


-- Wormhole codes use a "nameplate": a short name which is only used to
-- reference a specific (long-named) mailbox. The codes only use numeric
-- nameplates, but the protocol and server allow can use arbitrary strings.
CREATE TABLE `nameplates`
(
 `id` INTEGER PRIMARY KEY AUTOINCREMENT,
 `app_id` VARCHAR,
 `name` VARCHAR,
 `mailbox_id` VARCHAR, -- really a foreign key
 `request_id` VARCHAR, -- from 'allocate' message, for future deduplication
 `updated` INTEGER -- time of last activity, used for pruning
);
CREATE INDEX `nameplates_idx` ON `nameplates` (`app_id`, `name`);
CREATE INDEX `nameplates_updated_idx` ON `nameplates` (`app_id`, `updated`);
CREATE INDEX `nameplates_mailbox_idx` ON `nameplates` (`app_id`, `mailbox_id`);
CREATE INDEX `nameplates_request_idx` ON `nameplates` (`app_id`, `request_id`);

CREATE TABLE `nameplate_sides`
(
 `nameplates_id` REFERENCES `nameplates`(`id`),
 `claimed` BOOLEAN, -- True after claim(), False after release()
 `side` VARCHAR,
 `added` INTEGER -- time when this side first claimed the nameplate
);


-- Clients exchange messages through a "mailbox", which has a long (randomly
-- unique) identifier and a queue of messages.
CREATE TABLE `mailboxes`
(
 `app_id` VARCHAR,
 `id` VARCHAR,
 `side1` VARCHAR, -- side name, or NULL
 `side2` VARCHAR, -- side name, or NULL
 `crowded` BOOLEAN, -- at some point, three or more sides were involved
 `first_mood` VARCHAR,
 -- timing data for the mailbox itself
 `started` INTEGER, -- time when opened
 `second` INTEGER -- time when second side opened
);
CREATE INDEX `mailboxes_idx` ON `mailboxes` (`app_id`, `id`);

CREATE TABLE `messages`
(
 `app_id` VARCHAR,
 `mailbox_id` VARCHAR,
 `side` VARCHAR,
 `phase` VARCHAR, -- numeric or string
 `body` VARCHAR,
 `server_rx` INTEGER,
 `msg_id` VARCHAR
);
CREATE INDEX `messages_idx` ON `messages` (`app_id`, `mailbox_id`);

CREATE TABLE `nameplate_usage`
(
 `app_id` VARCHAR,
 `started` INTEGER, -- seconds since epoch, rounded to "blur time"
 `waiting_time` INTEGER, -- seconds from start to 2nd side appearing, or None
 `total_time` INTEGER, -- seconds from open to last close/prune
 `result` VARCHAR -- happy, lonely, pruney, crowded
 -- nameplate moods:
 --  "happy": two sides open and close
 --  "lonely": one side opens and closes (no response from 2nd side)
 --  "pruney": channels which get pruned for inactivity
 --  "crowded": three or more sides were involved
);
CREATE INDEX `nameplate_usage_idx` ON `nameplate_usage` (`app_id`, `started`);

CREATE TABLE `mailbox_usage`
(
 `app_id` VARCHAR,
 `started` INTEGER, -- seconds since epoch, rounded to "blur time"
 `total_time` INTEGER, -- seconds from open to last close
 `waiting_time` INTEGER, -- seconds from start to 2nd side appearing, or None
 `result` VARCHAR -- happy, scary, lonely, errory, pruney
 -- rendezvous moods:
 --  "happy": both sides close with mood=happy
 --  "scary": any side closes with mood=scary (bad MAC, probably wrong pw)
 --  "lonely": any side closes with mood=lonely (no response from 2nd side)
 --  "errory": any side closes with mood=errory (other errors)
 --  "pruney": channels which get pruned for inactivity
 --  "crowded": three or more sides were involved
);
CREATE INDEX `mailbox_usage_idx` ON `mailbox_usage` (`app_id`, `started`);

CREATE TABLE `transit_usage`
(
 `started` INTEGER, -- seconds since epoch, rounded to "blur time"
 `total_time` INTEGER, -- seconds from open to last close
 `waiting_time` INTEGER, -- seconds from start to 2nd side appearing, or None
 `total_bytes` INTEGER, -- total bytes relayed (both directions)
 `result` VARCHAR -- happy, scary, lonely, errory, pruney
 -- transit moods:
 --  "errory": one side gave the wrong handshake
 --  "lonely": good handshake, but the other side never showed up
 --  "happy": both sides gave correct handshake
);
CREATE INDEX `transit_usage_idx` ON `transit_usage` (`started`);
