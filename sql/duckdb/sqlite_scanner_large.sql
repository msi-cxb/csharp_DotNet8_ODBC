.echo ON
.timer ON

PRAGMA version;

-- RESULT:current_setting('threads')
-- RESULT:6
SELECT current_setting('threads');

-- remove database to start fresh
.system del /Q [[__DATAFOLDER__]]\new_sqlite_database.* > nul 2>&1

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

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from sqlite_db.large_table;

.print ********************************************************
.print you can copy tables directly from sqlite to duckdb
.print ********************************************************
CREATE OR REPLACE TABLE large_table AS FROM sqlite_db.large_table;

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from large_table;

.print ********************************************************
.print you can copy tables directly from duckdb to sqlite
.print ********************************************************
CREATE OR REPLACE TABLE sqlite_db.new_large_table AS FROM large_table;

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from sqlite_db.new_large_table;

-- RESULT:id,hash,rand,value
-- RESULT:10000,7835423671037039418,0,0.009626607812609465
-- RESULT:9999,6554257652517164275,1,0.06283780913628263
-- RESULT:9999,6554257652517164275,0,0.7334942919165739
-- RESULT:9998,1275346516494478339,0,0.4791401524453945
-- RESULT:9998,1275346516494478339,0,0.8491802790838683
select * from sqlite_db.large_table order by id desc,value limit 5;

-- RESULT:id,hash,rand,value
-- RESULT:10000,7835423671037039418,0,0.009626607812609465
-- RESULT:9999,6554257652517164275,1,0.06283780913628263
-- RESULT:9999,6554257652517164275,0,0.7334942919165739
-- RESULT:9998,1275346516494478339,0,0.4791401524453945
-- RESULT:9998,1275346516494478339,0,0.8491802790838683
select * from large_table order by id desc,value limit 5;

-- RESULT:id,hash,rand,value
-- RESULT:10000,7835423671037039418,0,0.009626607812609465
-- RESULT:9999,6554257652517164275,1,0.06283780913628263
-- RESULT:9999,6554257652517164275,0,0.7334942919165739
-- RESULT:9998,1275346516494478339,0,0.4791401524453945
-- RESULT:9998,1275346516494478339,0,0.8491802790838683
select * from sqlite_db.new_large_table order by id desc,value limit 5;

DROP TABLE IF EXISTS sqlite_db.large_table;
DROP TABLE IF EXISTS large_table;
DROP TABLE IF EXISTS sqlite_db.new_large_table;


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

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from large_table;

.print ********************************************************
.print you can copy tables directly from duckdb to sqlite
.print ********************************************************
CREATE OR REPLACE TABLE sqlite_db.large_table AS FROM large_table;

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from sqlite_db.large_table;

.print ********************************************************
.print you can copy tables directly from sqlite to duckdb
.print ********************************************************
CREATE OR REPLACE TABLE new_large_table AS FROM sqlite_db.large_table;

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from new_large_table;

-- RESULT:id,hash,rand,value
-- RESULT:10000,7835423671037039418,0,0.009626607812609465
-- RESULT:9999,6554257652517164275,1,0.06283780913628263
-- RESULT:9999,6554257652517164275,0,0.7334942919165739
-- RESULT:9998,1275346516494478339,0,0.4791401524453945
-- RESULT:9998,1275346516494478339,0,0.8491802790838683
select * from large_table order by id desc,value limit 5;

-- RESULT:id,hash,rand,value
-- RESULT:10000,7835423671037039418,0,0.009626607812609465
-- RESULT:9999,6554257652517164275,1,0.06283780913628263
-- RESULT:9999,6554257652517164275,0,0.7334942919165739
-- RESULT:9998,1275346516494478339,0,0.4791401524453945
-- RESULT:9998,1275346516494478339,0,0.8491802790838683
select * from sqlite_db.large_table order by id desc,value limit 5;

-- RESULT:id,hash,rand,value
-- RESULT:10000,7835423671037039418,0,0.009626607812609465
-- RESULT:9999,6554257652517164275,1,0.06283780913628263
-- RESULT:9999,6554257652517164275,0,0.7334942919165739
-- RESULT:9998,1275346516494478339,0,0.4791401524453945
-- RESULT:9998,1275346516494478339,0,0.8491802790838683
select * from new_large_table order by id desc,value limit 5;

DETACH sqlite_db;

-- remove database to start fresh
.system del /Q [[__DATAFOLDER__]]\new_sqlite_database.* > nul 2>&1
