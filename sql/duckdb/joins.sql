.echo on
-- .timer on
.conn duckdb

-- https://duckdb.org/docs/stable/sql/query_syntax/from

.print **********************************
.print TODO add other joins here...

.print **********************************
.print lateral join
-- The LATERAL keyword allows subqueries in the FROM clause to refer to previous subqueries. This feature is also known as a lateral join.

-- RESULT:i,j
-- RESULT:0,1
-- RESULT:1,2
-- RESULT:2,3
SELECT * FROM range(3) t(i), LATERAL (SELECT i + 1) t2(j);

-- RESULT:i,j
-- RESULT:0,10
-- RESULT:1,11
-- RESULT:0,100
-- RESULT:1,101
SELECT * FROM
    generate_series(0, 1) t(i),
    LATERAL (SELECT i + 10 UNION ALL SELECT i + 100) t2(j);

CREATE OR REPLACE TABLE t1 AS
    SELECT *
    FROM range(3) t(i), LATERAL (SELECT i + 1) t2(j);

-- RESULT:i,j,k
-- RESULT:0,1,1
-- RESULT:1,2,3
-- RESULT:2,3,5
SELECT *
    FROM t1, LATERAL (SELECT i + j) t2(k)
    ORDER BY ALL;

.print **********************************
.print postional join
-- When working with data frames or other embedded tables of the same size, the rows may have a natural correspondence based on their physical order.
-- It is difficult to express this in standard SQL because relational tables are not ordered, but imported tables such as data frames or disk files
-- (like CSVs or Parquet files) do have a natural ordering. Connecting them using this ordering is called a positional join.
-- Positional joins are always FULL OUTER joins, i.e., missing values (the last values in the shorter column) are set to NULL.

CREATE OR REPLACE TABLE t1 (x INTEGER);
CREATE OR REPLACE TABLE t2 (s VARCHAR);

INSERT INTO t1 VALUES (1), (2), (3);
INSERT INTO t2 VALUES ('a'), ('b');

-- RESULT:x,s
-- RESULT:1,a
-- RESULT:2,b
-- RESULT:3,null
SELECT * FROM t1 POSITIONAL JOIN t2;

.print **********************************
.print self join

CREATE OR REPLACE TABLE t (x INTEGER);

INSERT INTO t VALUES (1), (2), (3);

-- RESULT:x
-- RESULT:1
-- RESULT:2
-- RESULT:3
SELECT * FROM t;

-- RESULT:x
-- RESULT:1
-- RESULT:2
-- RESULT:3
SELECT * FROM t AS t1 JOIN t AS t2 USING(x);

-- RESULT:x,x
-- RESULT:1,1
-- RESULT:2,2
-- RESULT:3,3
SELECT * FROM t AS t1 JOIN t AS t2 ON t1.x = t2.x;

-- RESULT:x,x
-- RESULT:1,1
-- RESULT:2,2
-- RESULT:3,3
SELECT * FROM t  t1, t t2 where t1.x = t2.x;




