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

CREATE OR REPLACE TABLE Users (
    user_id INT PRIMARY KEY,
    name VARCHAR(50),
    age INT
);

CREATE OR REPLACE TABLE Friendships (
    friendship_id INT PRIMARY KEY,
    source_user_id INT,
    target_user_id INT,
    since_date DATE,
    FOREIGN KEY (source_user_id) REFERENCES Users(user_id),
    FOREIGN KEY (target_user_id) REFERENCES Users(user_id)
);

INSERT INTO Users (user_id, name, age) VALUES
    (1, 'Alice', 30),
    (2, 'Bob', 25),
    (3, 'Charlie', 35),
    (4, 'David', 28);

INSERT INTO Friendships (friendship_id, source_user_id, target_user_id, since_date) VALUES
    (101, 1, 2, '2022-01-15'),
    (102, 1, 3, '2021-11-20'),
    (103, 2, 3, '2023-03-10'),
    (104, 3, 4, '2024-06-01');

-- RESULT:user_id,name,age
-- RESULT:1,Alice,30
-- RESULT:2,Bob,25
-- RESULT:3,Charlie,35
-- RESULT:4,David,28
FROM Users;

-- RESULT:friendship_id,source_user_id,target_user_id,since_date
-- RESULT:101,1,2,20220115120000
-- RESULT:102,1,3,20211120120000
-- RESULT:103,2,3,20230310120000
-- RESULT:104,3,4,20240601120000
FROM Friendships;

CREATE OR REPLACE PROPERTY GRAPH friends
  VERTEX TABLES (
    Users
  )
  EDGE TABLES (
    Friendships SOURCE KEY (source_user_id) REFERENCES Users (user_id)
                DESTINATION KEY (target_user_id) REFERENCES Users (user_id)
    LABEL knows
  );

.print *******************************
CREATE OR REPLACE TABLE graph AS
SELECT * FROM GRAPH_TABLE (
    friends
    MATCH (a:Users)-[k:knows]->(b:Users)
    COLUMNS (a.name as user, b.name as friend, k.since_date as since_date)
);

.print *******************************
select * from graph;

.output first.gv false
SELECT 'digraph G {' as graph
UNION ALL
SELECT '  ' || name || ' [shape=box];' FROM Users
UNION ALL
SELECT '  ' || g.user || ' -> ' || g."friend" || ' [label="since ' || g."since_date" || '"];'
FROM graph AS g
GROUP BY g.user, g."friend", g."since_date"
UNION ALL
SELECT '}';
.output

.system dot -Tpng first.gv > first.png && start first.png

DROP PROPERTY GRAPH IF EXISTS friends;
