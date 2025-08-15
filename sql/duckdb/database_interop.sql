.echo on
.timer on

-- cleanup any previous ducklake database files
.system del /Q "[[__DATAFOLDER__]]\big_table.csv"
.system del /Q "[[__DATAFOLDER__]]\big_table.parquet"
.system del /Q "[[__DBFOLDER__]]\big_table.sqlite3"

.print create 25M record big table

-- -- make a large table in duckdb
CREATE OR REPLACE TABLE big_table (
    id BIGINT,
    hash UINT64,
    rand DOUBLE,
    value DOUBLE
);

SELECT SETSEED(0.42);

INSERT INTO big_table 
    select 
        (i+j) AS id, 
        hash(i+j) AS hash, 
        IF (j % 2, true, false) AS value, 
        RANDOM() as value 
    from 
        generate_series(1, 5000) s(i) 
    CROSS JOIN 
        generate_series(1, 5000) t(j);

.print duckdb

ANALYZE;

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from big_table;

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:id,BIGINT,YES,null,null,null
-- RESULT:hash,UBIGINT,YES,null,null,null
-- RESULT:rand,DOUBLE,YES,null,null,null
-- RESULT:value,DOUBLE,YES,null,null,null
DESCRIBE big_table;

.print csv

-- make a large table as csv
COPY big_table TO '[[__DATAFOLDER__]]\big_table.csv' (HEADER, DELIMITER ',', OVERWRITE_OR_IGNORE);

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from '[[__DATAFOLDER__]]\big_table.csv';

.print note the conversion of hash type from UBIGINT to DOUBLE

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:id,BIGINT,YES,null,null,null
-- RESULT:hash,DOUBLE,YES,null,null,null
-- RESULT:rand,DOUBLE,YES,null,null,null
-- RESULT:value,DOUBLE,YES,null,null,null
DESCRIBE '[[__DATAFOLDER__]]\big_table.csv';;

.print parquet

-- make a large table as parquet
COPY big_table TO '[[__DATAFOLDER__]]\big_table.parquet';

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from '[[__DATAFOLDER__]]\big_table.parquet';

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:id,BIGINT,YES,null,null,null
-- RESULT:hash,UBIGINT,YES,null,null,null
-- RESULT:rand,DOUBLE,YES,null,null,null
-- RESULT:value,DOUBLE,YES,null,null,null
DESCRIBE '[[__DATAFOLDER__]]\big_table.parquet';;

.print sqlite

-- make a large table in sqlite
FORCE INSTALL sqlite_scanner from '.\local_extensions';
LOAD sqlite_scanner;
ATTACH '[[__DBFOLDER__]]\big_table.sqlite3' AS big_table_sqlite (TYPE sqlite);

CREATE TABLE big_table_sqlite.big_table AS SELECT * FROM big_table;

ANALYZE;

-- RESULT:cnt
-- RESULT:25000000
select count(1) as cnt from big_table_sqlite.big_table;

.print note the conversion of hash type from UBIGINT to VARCHAR

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:id,BIGINT,YES,null,null,null
-- RESULT:hash,VARCHAR,YES,null,null,null
-- RESULT:rand,DOUBLE,YES,null,null,null
-- RESULT:value,DOUBLE,YES,null,null,null
DESCRIBE select * from big_table_sqlite.big_table;


