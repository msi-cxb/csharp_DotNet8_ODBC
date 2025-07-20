.echo ON
.timer ON

PRAGMA version;

-- RESULT:current_setting('threads')
-- RESULT:6
SELECT current_setting('threads');

-- remove data.parquet to start fresh
.system del /Q [[__DATAFOLDER__]]\new_sqlite_database.* > nul 2>&1
.system del /Q [[__DATAFOLDER__]]\large_table_sqlite.parquet > nul 2>&1

.print install sqlite_scanner from local extensions repo (note these are signed copies from core)
FORCE INSTALL sqlite_scanner from '.\local_extensions';
-- INSTALL sqlite_scanner;
LOAD sqlite_scanner;

ATTACH '[[__DBFOLDER__]]/new_sqlite_database.db' AS sqlite_db (TYPE sqlite);

.print build a large_table in attached sqlite3 database file via sqlite_scanner
CREATE OR REPLACE TABLE sqlite_db.large_table (
    id BIGINT,
    hash UINT64,
    rand DOUBLE,
    value DOUBLE
);

-- so that results are same
SELECT SETSEED(0.42);

.print *******************************************
.print insert 25,000,000 records via CTE (approx 1 GB)
INSERT INTO sqlite_db.large_table 
select 
    (i+j) AS id, 
    hash(i+j) AS hash, 
    IF (j % 2, true, false) AS value,
    RANDOM() as value 
from generate_series(1, 5000) s(i) 
CROSS JOIN generate_series(1, 5000) t(j);

-- 25,000,000 records
-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from sqlite_db.large_table;

-- RESULT:id,hash,rand,value
-- RESULT:2,2060787363917578834,1,0.747204143391125
-- RESULT:3,8131803788478518982,0,0.5726404382373844
-- RESULT:3,8131803788478518982,1,0.6736244023239688
-- RESULT:4,8535942711051191036,0,0.02148794940409058
-- RESULT:4,8535942711051191036,1,0.34597365227268895
-- RESULT:4,8535942711051191036,1,0.6039073183711521
-- RESULT:5,4244145009296420692,0,0.43885053449014805
-- RESULT:5,4244145009296420692,0,0.7665807217848326
select * from sqlite_db.large_table order by id,value limit 8;

.print *******************************************
.print copy data from sqlite to duckdb via parquet
COPY sqlite_db.large_table TO '[[__DATAFOLDER__]]/large_table_sqlite.parquet';
CREATE OR REPLACE TABLE large_table_sqlite AS SELECT * FROM '[[__DATAFOLDER__]]/large_table_sqlite.parquet';

-- 25,000,000 records
-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from large_table_sqlite;

-- RESULT:id,hash,rand,value
-- RESULT:2,2060787363917578834,1,0.747204143391125
-- RESULT:3,8131803788478518982,0,0.5726404382373844
-- RESULT:3,8131803788478518982,1,0.6736244023239688
-- RESULT:4,8535942711051191036,0,0.02148794940409058
-- RESULT:4,8535942711051191036,1,0.34597365227268895
-- RESULT:4,8535942711051191036,1,0.6039073183711521
-- RESULT:5,4244145009296420692,0,0.43885053449014805
-- RESULT:5,4244145009296420692,0,0.7665807217848326
select * from large_table_sqlite order by id,value limit 8;

.print *******************************************
.print build a large_table in duckdb database file
CREATE OR REPLACE TABLE large_table (
    id BIGINT,
    hash UINT64,
    rand DOUBLE,
    value DOUBLE
);

-- so that results are same
SELECT SETSEED(0.42);

-- here is a case where duckdb insert into is fast...
INSERT INTO large_table 
select 
    (i+j) AS id, 
    hash(i+j) AS hash, 
    IF (j % 2, true, false) AS value,
    RANDOM() as value 
from generate_series(1, 5000) s(i) 
CROSS JOIN generate_series(1, 5000) t(j);

-- 25,000,000 records
-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from large_table;

-- RESULT:id,hash,rand,value
-- RESULT:2,2060787363917578834,1,0.747204143391125
-- RESULT:3,8131803788478518982,0,0.5726404382373844
-- RESULT:3,8131803788478518982,1,0.6736244023239688
-- RESULT:4,8535942711051191036,0,0.02148794940409058
-- RESULT:4,8535942711051191036,1,0.34597365227268895
-- RESULT:4,8535942711051191036,1,0.6039073183711521
-- RESULT:5,4244145009296420692,0,0.43885053449014805
-- RESULT:5,4244145009296420692,0,0.7665807217848326
select * from large_table order by id,value limit 8;
