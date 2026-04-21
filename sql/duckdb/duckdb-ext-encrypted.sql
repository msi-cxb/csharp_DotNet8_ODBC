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

-- RESULT:name
-- RESULT:ans
-- RESULT:customer
-- RESULT:lineitem1
-- RESULT:lineitem2
-- RESULT:nation
-- RESULT:orders
-- RESULT:part
-- RESULT:partsupp
-- RESULT:region
-- RESULT:supplier
SHOW tables;

.print ================ ATTACH tpch_unencrypted
ATTACH '[[__DBFOLDER__]]\tpch_unencrypted.duckdb' AS unencrypted;
-- COPY FROM DATABASE encrypted TO unencrypted;

USE unencrypted;

-- RESULT:name
-- RESULT:ans
-- RESULT:customer
-- RESULT:lineitem1
-- RESULT:lineitem2
-- RESULT:nation
-- RESULT:orders
-- RESULT:part
-- RESULT:partsupp
-- RESULT:region
-- RESULT:supplier
SHOW tables;

.print ================ To keep track of which databases are encrypted, you can query this 'FROM duckdb_databases();':
-- RESULT:database_name,readonly,encrypted,cipher
-- RESULT:unencrypted,false,false,null
-- RESULT:test,false,false,null
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
SUMMARIZE unencrypted.lineitem1;

.print ================ SUMMARIZE encrypted.lineitem1
SUMMARIZE encrypted.lineitem1;

RESET memory_limit;
SELECT current_setting('memory_limit');
RESET threads;
SELECT current_setting('threads');

.print ================ should be two entries...one from each table so result is empty table
PREPARE count_table AS 
SELECT *, COUNT(*) as count
FROM (
    SELECT * FROM query_table($1)
    UNION ALL
    SELECT * FROM query_table($2)
) t
GROUP BY ALL
HAVING count != 2;

EXECUTE count_table('unencrypted.lineitem1','encrypted.lineitem1');
EXECUTE count_table('unencrypted.lineitem2','encrypted.lineitem2');
EXECUTE count_table('unencrypted.customer','encrypted.customer');
EXECUTE count_table('unencrypted.nation','encrypted.nation');
EXECUTE count_table('unencrypted.part','encrypted.part');
EXECUTE count_table('unencrypted.region','encrypted.region');
EXECUTE count_table('unencrypted.orders','encrypted.orders');
EXECUTE count_table('unencrypted.partsupp','encrypted.partsupp');
EXECUTE count_table('unencrypted.supplier','encrypted.supplier');
EXECUTE count_table('unencrypted.ans','encrypted.ans');

.print ================ are unencrypted/encrypted tables the same?
PREPARE compare_table AS 
SELECT NOT EXISTS (
    SELECT * FROM query_table($1)  EXCEPT SELECT * FROM query_table($2) 
    UNION ALL
    SELECT * FROM query_table($2)  EXCEPT SELECT * FROM query_table($1)
) AS are_identical;

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.lineitem1','encrypted.lineitem1');

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.lineitem2','encrypted.lineitem2');

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.customer','encrypted.customer');

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.nation','encrypted.nation');

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.part','encrypted.part');

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.region','encrypted.region');

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.orders','encrypted.orders');

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.partsupp','encrypted.partsupp');

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.supplier','encrypted.supplier');

-- RESULT:are_identical
-- RESULT:true
EXECUTE compare_table('unencrypted.ans','encrypted.ans');

