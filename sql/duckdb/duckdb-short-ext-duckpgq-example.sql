.echo on
-- .timer on
.conn duckdb

-- https://duckdb.org/community_extensions/extensions/duckpgq

.print *************************************************
.print version 1.5.2 not currently available
.next

PRAGMA version;

-- RESULT:threads
-- RESULT:6
SELECT current_setting('threads') AS threads;

.print *************************************************
-- FORCE INSTALL duckpgq from '.\extensions\duckdb';
INSTALL duckpgq FROM community;
LOAD duckpgq;

CREATE OR REPLACE TABLE Person AS SELECT * FROM 'https://gist.githubusercontent.com/Dtenwolde/2b02aebbed3c9638a06fda8ee0088a36/raw/8c4dc551f7344b12eaff2d1438c9da08649d00ec/person-sf0.003.csv';
CREATE OR REPLACE TABLE Person_knows_person AS SELECT * FROM 'https://gist.githubusercontent.com/Dtenwolde/81c32c9002d4059c2c3073dbca155275/raw/8b440e810a48dcaa08c07086e493ec0e2ec6b3cb/person_knows_person-sf0.003.csv';

CREATE OR REPLACE PROPERTY GRAPH snb
  VERTEX TABLES (
    Person
  )
  EDGE TABLES (
    Person_knows_person SOURCE KEY (Person1Id) REFERENCES Person (id)
                        DESTINATION KEY (Person2Id) REFERENCES Person (id)
    LABEL knows
  );
  
PRAGMA show_property_graphs;

FROM GRAPH_TABLE (snb
  MATCH (a:Person)
  COLUMNS (a.id)
);

FROM GRAPH_TABLE (snb
  MATCH (a:Person)-[k:knows]->(b:Person)
  COLUMNS (a.id, b.id)
)
LIMIT 1;

FROM GRAPH_TABLE (snb 
  MATCH p = ANY SHORTEST (a:person)-[k:knows]->{1,3}(b:Person) 
  COLUMNS (a.id, b.id, path_length(p))
) 
LIMIT 1;

FROM local_clustering_coefficient(snb, person, knows);

DROP PROPERTY GRAPH snb;