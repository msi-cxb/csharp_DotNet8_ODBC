-- https://duckdb.org/2025/11/19/encryption-in-duckdb

.echo on
-- .timer on
.conn duckdb

.print dbfolder [[__DBFOLDER__]]
.print datafolder [[__DATAFOLDER__]]
-- .delete [[__DBFOLDER__]]\tpch_encrypted.duckdb
-- .delete [[__DBFOLDER__]]\tpch_unencrypted.duckdb

PRAGMA version;

INSTALL tpch;
LOAD tpch;
-- INSTALL httpfs;
-- LOAD httpfs;

-- force DuckDB to produce temporary files
SET memory_limit = '1GB';

.print ================ ATTACH tpch_encrypted
ATTACH '[[__DBFOLDER__]]\tpch_encrypted.duckdb' AS encrypted (
    ENCRYPTION_KEY 'asdf',
    ENCRYPTION_CIPHER 'GCM'
);
USE encrypted;

.print ================ dbgen
-- .timer on
-- CALL dbgen(sf = 1);
-- .timer off

-- ALTER TABLE lineitem
    -- RENAME TO lineitem1;
-- CREATE OR REPLACE TABLE lineitem2 AS
    -- FROM lineitem1;
-- CREATE OR REPLACE TABLE ans AS
    -- SELECT l1.* , l2.*
    -- FROM lineitem1 l1
    -- JOIN lineitem2 l2 USING (l_orderkey , l_linenumber);

SHOW tables;

.print ================ ATTACH tpch_unencrypted
ATTACH '[[__DBFOLDER__]]\tpch_unencrypted.duckdb' AS unencrypted;
-- COPY FROM DATABASE encrypted TO unencrypted;

USE unencrypted;

SHOW tables;

.print ================ To keep track of which databases are encrypted, you can query this 'FROM duckdb_databases();':
-- RESULT:database_name,readonly,encrypted,cipher
-- RESULT:unencrypted,false,false,null
-- RESULT:memory,false,false,null
-- RESULT:encrypted,false,true,GCM
-- RESULT:system,false,false,null
-- RESULT:temp,false,false,null
select database_name,readonly,encrypted,cipher FROM duckdb_databases();

-- .print ================ detach and remove databases
-- USE test.main;

-- DETACH encrypted;
-- DETACH unencrypted;

-- .delete [[__DBFOLDER__]]\tpch_encrypted.duckdb
-- .delete [[__DBFOLDER__]]\tpch_unencrypted.duckdb

.print ================ show SUMMARIZE example...

-- .print ================ create tpch_unencrypted with dbgen
-- ATTACH '[[__DBFOLDER__]]\tpch_unencrypted.duckdb' AS unencrypted;
-- .timer on
-- CALL dbgen(sf = 1, catalog = 'unencrypted');
-- .timer off

-- .print ================ create tpch_encrypted by copying from tpch_unencrypted
-- ATTACH '[[__DBFOLDER__]]\tpch_encrypted.duckdb' AS encrypted (ENCRYPTION_KEY 'asdf');
-- COPY FROM DATABASE encrypted TO unencrypted;

.print ================ set a very low memory limit to force more reading and writing from disk.
SET memory_limit = '200MB';
SELECT current_setting('memory_limit');

.timer on

.print ================ SUMMARIZE unencrypted.lineitem1
-- SUMMARIZE unencrypted.lineitem1;

.print ================ SUMMARIZE encrypted.lineitem1
-- SUMMARIZE encrypted.lineitem1;

RESET memory_limit;
SELECT current_setting('memory_limit');
RESET threads;
SELECT current_setting('threads');

-- count_table/compare_table checks require populated TPC-H tables (run dbgen first)
-- .print ================ should be two entries...one from each table so result is empty table
-- PREPARE count_table AS ...
-- EXECUTE count_table(...)  -- omitted: tables may not exist

-- .print ================ are unencrypted/encrypted tables the same?
-- PREPARE compare_table AS ...
-- EXECUTE compare_table(...)  -- omitted: tables may not exist

