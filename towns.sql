CREATE TABLE towns (
   town VARCHAR(64),
   state VARCHAR(2),
   state_num TINYINT NOT NULL,
   county VARCHAR(64),
   county_num SMALLINT NOT NULL,
   elevation INTEGER
);

CREATE TABLE people (
 state_num TINYINT NOT NULL,
 county_num SMALLINT NOT NULL,
   state VARCHAR(20),
   county VARCHAR(64),
   population INTEGER
 );

