.echo on
-- .timer on
.conn duckdb

-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.1,b390a7c376,Andium
PRAGMA version;

-- RESULT:threads
-- RESULT:6
SELECT current_setting('threads') AS threads;

.print *************************************************
-- FORCE INSTALL duckpgq from '.\local_extensions';
INSTALL duckpgq FROM community;
LOAD duckpgq;

ATTACH 'https://github.com/Dtenwolde/duckpgq-docs/raw/refs/heads/main/datasets/snb.duckdb';

use snb;
install duckpgq from community; 
load duckpgq;

CREATE or replace PROPERTY GRAPH snb
VERTEX TABLES (
  Person, Forum
)
EDGE TABLES (
  Person_knows_person     SOURCE KEY (Person1Id) REFERENCES Person (id)
                          DESTINATION KEY (Person2Id) REFERENCES Person (id)
                          LABEL knows,
  Forum_hasMember_Person  SOURCE KEY (ForumId) REFERENCES Forum (id)
                          DESTINATION KEY (PersonId) REFERENCES Person (id)
                          LABEL hasMember
);

-- find the shortest path from one person to all other persons
-- RESULT:id,other_person_id,element_id(p),path_length(p)
-- RESULT:14,14,[0],0
-- RESULT:14,10995116277782,[0, 0, 13],1
-- RESULT:14,24189255811081,[0, 1, 26],1
-- RESULT:14,24189255811109,[0, 1, 26, 61, 27],2
-- RESULT:14,26388279066641,[0, 0, 13, 42, 29],2
-- RESULT:14,26388279066658,[0, 0, 13, 43, 31],2
-- RESULT:14,26388279066668,[0, 2, 32],1
-- RESULT:14,28587302322180,[0, 0, 13, 44, 33],2
-- RESULT:14,28587302322196,[0, 1, 26, 65, 35],2
-- RESULT:14,28587302322204,[0, 0, 13, 45, 36],2
-- RESULT:14,28587302322223,[0, 0, 13, 44, 33, 78, 38],3
-- RESULT:14,30786325577731,[0, 0, 13, 44, 33, 79, 39],3
-- RESULT:14,30786325577740,[0, 0, 13, 43, 31, 72, 40],3
-- RESULT:14,32985348833329,[0, 0, 13, 44, 33, 80, 43],3
-- RESULT:14,35184372088834,[0, 1, 26, 66, 44],2
-- RESULT:14,35184372088850,[0, 0, 13, 43, 31, 73, 45],3
-- RESULT:14,35184372088856,[0, 0, 13, 46, 46],2
FROM GRAPH_TABLE (snb
  MATCH p = ANY SHORTEST (p1:person WHERE p1.id = 14)-[k:knows]->*(p2:person)
  COLUMNS (p1.id, p2.id as other_person_id, element_id(p), path_length(p))
);

-- Find mutual friends between two users
-- RESULT:firstName
-- RESULT:Ali
FROM GRAPH_TABLE (snb
  MATCH (p1:Person WHERE p1.id = 16)-[k:knows]->(p2:Person)<-[k2:knows]-(p3:Person WHERE p3.id = 32)
  COLUMNS (p2.firstName)
);

-- Find the 3 most popular people 
-- RESULT:personID,firstName,lastName,numFollowers
-- RESULT:24189255811081,Alim,Guliyev,10
-- RESULT:26388279066658,Roberto,Diaz,9
-- RESULT:28587302322180,Bryn,Davies,9
FROM GRAPH_TABLE (snb
  MATCH (follower:Person)-[follows:knows]->(person:Person)
  COLUMNS (person.id AS personID, person.firstname, person.lastname, follower.id AS followerID)
)
SELECT personID, firstname, lastname, COUNT(followerID) AS numFollowers
GROUP BY ALL 
ORDER BY numFollowers DESC 
LIMIT 3;

-- Number of forums posted on by the most followed person
-- Fatal error. System.AccessViolationException: Attempted to read or write protected memory.
WITH
mfp AS (
  FROM GRAPH_TABLE (snb
    MATCH (follower:Person)-[follows:knows]->(person:Person)
    COLUMNS (person.id AS personID, person.firstname, follower.id AS followerID)
  )
SELECT personID, firstname, COUNT(followerID) AS numFollowers
GROUP BY ALL ORDER BY numFollowers DESC LIMIT 1
)
FROM
  mfp,
  GRAPH_TABLE (snb
    MATCH (person:Person)<-[fhm:hasMember]-(f:Forum)
    COLUMNS (person.id AS personID, f.id as forumId)
) mem
SELECT mfp.personID, mfp.firstname, mfp.numFollowers, count(mem.forumId) forumCount
WHERE mfp.personID = mem.personID
GROUP BY ALL;


DROP PROPERTY GRAPH snb;