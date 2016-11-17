CREATE TABLE towns (
   town VARCHAR(64),
   state VARCHAR(2),
   state_num TINYINT NOT NULL,
   county VARCHAR(64),
   county_num SMALLINT NOT NULL,
   elevation INTEGER
);

CREATE TABLE states (
   abbreviation VARCHAR(20),
   state_num TINYINT,
   name VARCHAR(20),
   PRIMARY KEY (state_num)
);

CREATE INDEX town_idx ON towns (state_num, county_num);
CREATE INDEX people_idx ON people (state_num, county_num);

CREATE TABLE people (
 state_num TINYINT NOT NULL,
 county_num SMALLINT NOT NULL,
   state VARCHAR(20),
   county VARCHAR(64),
   population INTEGER
 );

PARTITION TABLE towns ON COLUMN state_num;
PARTITION TABLE people ON COLUMN state_num;

ALTER TABLE towns DROP COLUMN state;
ALTER TABLE people DROP COLUMN state;

CREATE TABLE nws_event (
   id VARCHAR(256) NOT NULL,
   type VARCHAR(128),
   severity VARCHAR(128),
   SUMMARY VARCHAR(1024),
   starttime TIMESTAMP,
   endtime TIMESTAMP,
   updated TIMESTAMP,
   PRIMARY KEY (id)
);

CREATE INDEX nws_event_idx ON nws_event (id);

CREATE TABLE local_event (
    state_num TINYINT NOT NULL,
    county_num SMALLINT NOT NULL,
    id VARCHAR(256) NOT NULL
);

CREATE INDEX local_event_idx ON local_event (state_num, county_num);
 
PARTITION TABLE local_event ON COLUMN state_num;

CREATE PROCEDURE FindAlert AS
   SELECT id, updated FROM nws_event
   WHERE id = ?;

CREATE PROCEDURE FROM CLASS LoadAlert;

CREATE PROCEDURE GetAlertsByLocation 
   PARTITION ON TABLE local_event COLUMN state_num
   AS SELECT w.id, w.summary, w.type, w.severity,
             w.starttime, w.endtime 
             FROM nws_event as w, local_event as l
             WHERE l.id=w.id and 
                   l.state_num=? and l.county_num = ? and
                   w.endtime > TO_TIMESTAMP(MILLISECOND,?)
             ORDER BY w.endtime;
