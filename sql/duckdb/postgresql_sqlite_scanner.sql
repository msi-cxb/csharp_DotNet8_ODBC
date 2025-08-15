-- .echo on
-- .timer on
.conn duckdb

.print *************************************************
.print
.print copy tables between duckdb, postgresql, and sqlite3
.print
.print *************************************************

PRAGMA version;

-- RESULT:current_setting('threads')
-- RESULT:6
SELECT current_setting('threads');

-- remove database to start fresh
.system del /Q [[__DBFOLDER__]]\postgresql_sqlite_scanner.db > nul 2>&1

.print *************************************************
FORCE INSTALL sqlite_scanner from '.\local_extensions';
LOAD sqlite_scanner;

ATTACH '[[__DBFOLDER__]]/postgresql_sqlite_scanner.db' AS sqlite3_db (TYPE sqlite);

CREATE OR REPLACE TABLE sqlite3_db.sqlite3_table (id INTEGER, name VARCHAR);

INSERT INTO sqlite3_db.sqlite3_table VALUES (42, 'sqlite3');

-- RESULT:id,name
-- RESULT:42,sqlite3
SELECT * FROM sqlite3_db.sqlite3_table;

.print *************************************************
FORCE INSTALL postgres from '.\local_extensions';
LOAD postgres;

CREATE SECRET postgres_secret_one (
    TYPE postgres,
    HOST 'charlies-MacBook-Pro.local',
    PORT 5432,
    DATABASE 'postgres',
    USER 'postgres',
    PASSWORD 'postgres'
);

.print attach to postgres_db using SECRET
ATTACH '' AS postgres_db (TYPE postgres, SECRET postgres_secret_one);

DROP SCHEMA postgres_db.public CASCADE;

CREATE SCHEMA IF NOT EXISTS postgres_db.public;

CREATE OR REPLACE TABLE postgres_db.postgres_table (id INTEGER, name VARCHAR);

INSERT INTO postgres_db.postgres_table VALUES (43, 'postgres');

-- RESULT:id,name
-- RESULT:43,postgres
SELECT * FROM postgres_db.postgres_table;

.print *************************************************
CREATE OR REPLACE TABLE duckdb_table (id INTEGER, name VARCHAR);

INSERT INTO duckdb_table VALUES (44, 'duckdb');

-- RESULT:id,name
-- RESULT:44,duckdb
SELECT * FROM duckdb_table;

DESCRIBE sqlite3_db.sqlite3_table;
DESCRIBE postgres_db.postgres_table;
DESCRIBE duckdb_table;

.print swap tables between postgresql and sqlite3
CREATE OR REPLACE TABLE postgres_db.sqlite3_table AS FROM sqlite3_db.sqlite3_table;
CREATE OR REPLACE TABLE sqlite3_db.postgres_table AS FROM postgres_db.postgres_table;

.print copy all tables to duckdb
CREATE OR REPLACE TABLE postgres_db_sqlite3_table AS FROM postgres_db.sqlite3_table;
CREATE OR REPLACE TABLE sqlite3_db_postgres_table AS FROM sqlite3_db.postgres_table;
CREATE OR REPLACE TABLE postgres_db_postgres_table AS FROM postgres_db.postgres_table;
CREATE OR REPLACE TABLE sqlite3_db_sqlite3_table AS FROM sqlite3_db.sqlite3_table;

.print copy all duckdb tables back to postgresql and sqlite3
CREATE OR REPLACE TABLE postgres_db.postgres_db_sqlite3_table AS FROM postgres_db_sqlite3_table;
CREATE OR REPLACE TABLE postgres_db.sqlite3_db_postgres_table AS FROM sqlite3_db_postgres_table;
CREATE OR REPLACE TABLE postgres_db.postgres_db_postgres_table AS FROM postgres_db_postgres_table;
CREATE OR REPLACE TABLE postgres_db.sqlite3_db_sqlite3_table AS FROM sqlite3_db_sqlite3_table;
CREATE OR REPLACE TABLE postgres_db.duckdb_table AS FROM duckdb_table;

CREATE OR REPLACE TABLE sqlite3_db.postgres_db_sqlite3_table AS FROM postgres_db_sqlite3_table;
CREATE OR REPLACE TABLE sqlite3_db.sqlite3_db_postgres_table AS FROM sqlite3_db_postgres_table;
CREATE OR REPLACE TABLE sqlite3_db.postgres_db_postgres_table AS FROM postgres_db_postgres_table;
CREATE OR REPLACE TABLE sqlite3_db.sqlite3_db_sqlite3_table AS FROM sqlite3_db_sqlite3_table;
CREATE OR REPLACE TABLE sqlite3_db.duckdb_table AS FROM duckdb_table;

-- RESULT:id,name
-- RESULT:42,sqlite3
SELECT * FROM postgres_db.sqlite3_table;
-- RESULT:id,name
-- RESULT:43,postgres
SELECT * FROM sqlite3_db.postgres_table;
-- RESULT:id,name
-- RESULT:42,sqlite3
SELECT * FROM postgres_db_sqlite3_table;
-- RESULT:id,name
-- RESULT:43,postgres
SELECT * FROM sqlite3_db_postgres_table;
-- RESULT:id,name
-- RESULT:43,postgres
SELECT * FROM postgres_db_postgres_table;
-- RESULT:id,name
-- RESULT:42,sqlite3
SELECT * FROM sqlite3_db_sqlite3_table;
-- RESULT:id,name
-- RESULT:42,sqlite3
SELECT * FROM postgres_db.postgres_db_sqlite3_table;
-- RESULT:id,name
-- RESULT:43,postgres
SELECT * FROM postgres_db.sqlite3_db_postgres_table;
-- RESULT:id,name
-- RESULT:43,postgres
SELECT * FROM postgres_db.postgres_db_postgres_table;
-- RESULT:id,name
-- RESULT:42,sqlite3
SELECT * FROM postgres_db.sqlite3_db_sqlite3_table;
-- RESULT:id,name
-- RESULT:44,duckdb
SELECT * FROM postgres_db.duckdb_table;
-- RESULT:id,name
-- RESULT:42,sqlite3
SELECT * FROM sqlite3_db.postgres_db_sqlite3_table;
-- RESULT:id,name
-- RESULT:43,postgres
SELECT * FROM sqlite3_db.sqlite3_db_postgres_table;
-- RESULT:id,name
-- RESULT:43,postgres
SELECT * FROM sqlite3_db.postgres_db_postgres_table;
-- RESULT:id,name
-- RESULT:42,sqlite3
SELECT * FROM sqlite3_db.sqlite3_db_sqlite3_table;
-- RESULT:id,name
-- RESULT:44,duckdb
SELECT * FROM sqlite3_db.duckdb_table;

CREATE OR REPLACE TABLE all_rows (id INTEGER, name VARCHAR);

INSERT INTO all_rows FROM (
    SELECT * FROM postgres_db.sqlite3_table 
    UNION ALL 
    SELECT * FROM sqlite3_db.postgres_table 
    UNION ALL 
    SELECT * FROM postgres_db_sqlite3_table 
    UNION ALL 
    SELECT * FROM sqlite3_db_postgres_table 
    UNION ALL 
    SELECT * FROM postgres_db_postgres_table 
    UNION ALL 
    SELECT * FROM sqlite3_db_sqlite3_table 
    UNION ALL 
    SELECT * FROM postgres_db.postgres_db_sqlite3_table 
    UNION ALL 
    SELECT * FROM postgres_db.sqlite3_db_postgres_table 
    UNION ALL 
    SELECT * FROM postgres_db.postgres_db_postgres_table 
    UNION ALL 
    SELECT * FROM postgres_db.sqlite3_db_sqlite3_table 
    UNION ALL 
    SELECT * FROM postgres_db.duckdb_table 
    UNION ALL 
    SELECT * FROM sqlite3_db.postgres_db_sqlite3_table 
    UNION ALL 
    SELECT * FROM sqlite3_db.sqlite3_db_postgres_table 
    UNION ALL 
    SELECT * FROM sqlite3_db.postgres_db_postgres_table 
    UNION ALL 
    SELECT * FROM sqlite3_db.sqlite3_db_sqlite3_table 
    UNION ALL 
    SELECT * FROM sqlite3_db.duckdb_table
);

-- RESULT:id,name
-- RESULT:42,sqlite3
-- RESULT:43,postgres
-- RESULT:42,sqlite3
-- RESULT:43,postgres
-- RESULT:43,postgres
-- RESULT:42,sqlite3
-- RESULT:42,sqlite3
-- RESULT:43,postgres
-- RESULT:43,postgres
-- RESULT:42,sqlite3
-- RESULT:44,duckdb
-- RESULT:42,sqlite3
-- RESULT:43,postgres
-- RESULT:43,postgres
-- RESULT:42,sqlite3
-- RESULT:44,duckdb
select * from all_rows;

CREATE OR REPLACE TABLE tbls as select * from (SHOW) order by database,schema,name;

.print *************************************************
-- RESULT:rowid,database,schema,name,column_names,column_types,temporary
-- RESULT:0,postgres_db,public,duckdb_table,[id, name],[INTEGER, VARCHAR],false
-- RESULT:1,postgres_db,public,postgres_db_postgres_table,[id, name],[INTEGER, VARCHAR],false
-- RESULT:2,postgres_db,public,postgres_db_sqlite3_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:3,postgres_db,public,postgres_table,[id, name],[INTEGER, VARCHAR],false
-- RESULT:4,postgres_db,public,sqlite3_db_postgres_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:5,postgres_db,public,sqlite3_db_sqlite3_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:6,postgres_db,public,sqlite3_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:7,sqlite3_db,main,duckdb_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:8,sqlite3_db,main,postgres_db_postgres_table,[id, id, name, name],[BIGINT, BIGINT, VARCHAR, VARCHAR],false
-- RESULT:9,sqlite3_db,main,postgres_db_sqlite3_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:10,sqlite3_db,main,postgres_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:11,sqlite3_db,main,sqlite3_db_postgres_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:12,test,main,all_rows,[id, name],[INTEGER, VARCHAR],false
-- RESULT:13,test,main,duckdb_table,[id, name],[INTEGER, VARCHAR],false
-- RESULT:14,test,main,postgres_db_postgres_table,[id, name],[INTEGER, VARCHAR],false
-- RESULT:15,test,main,postgres_db_sqlite3_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:16,test,main,sqlite3_db_postgres_table,[id, name],[BIGINT, VARCHAR],false
-- RESULT:17,test,main,sqlite3_db_sqlite3_table,[id, name],[BIGINT, VARCHAR],false
select rowid, * from tbls where name != 'tbls' order by rowid;
 
DETACH sqlite3_db;

DETACH postgres_db;
