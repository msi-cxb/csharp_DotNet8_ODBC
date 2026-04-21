.echo on
-- .timer on
.conn duckdb

PRAGMA version;

.delete [[__DBFOLDER__]]\db1.duckdb
.delete [[__DBFOLDER__]]\db2.duckdb

ATTACH '[[__DBFOLDER__]]\db1.duckdb' AS db1;
ATTACH '[[__DBFOLDER__]]\db2.duckdb' AS db2;

USE db1;
CALL dbgen(sf = 1);
COPY FROM DATABASE db1 TO db2;

-- select count(1) as db1_lineitem_cnt from db1.lineitem;
-- select count(1) as db2_lineitem_cnt from db2.lineitem;

.print ================ set a very low memory limit to force more reading and writing from disk.
SET memory_limit = '200MB';
SELECT current_setting('memory_limit');

-- SUMMARIZE db1.lineitem;
-- SUMMARIZE db2.lineitem;

RESET memory_limit;
SELECT current_setting('memory_limit');

PREPARE compare_table AS 
SELECT NOT EXISTS (
    SELECT * FROM query_table($1)  EXCEPT SELECT * FROM query_table($2) 
    UNION ALL
    SELECT * FROM query_table($2)  EXCEPT SELECT * FROM query_table($1)
) AS are_identical;

-- this appears to be a bug in duckdb 
-- https://github.com/duckdb/duckdb/issues/22203
-- RESULT-ERROR:Out of Memory
EXECUTE compare_table('db1.lineitem','db2.lineitem');
