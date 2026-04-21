-- https://duckdb.org/2025/11/19/encryption-in-duckdb

.echo on
-- .timer on
.conn duckdb

.print dbfolder [[__DBFOLDER__]]
.print datafolder [[__DATAFOLDER__]]
.delete [[__DBFOLDER__]]\tpch_encrypted.duckdb
.delete [[__DBFOLDER__]]\tpch_unencrypted.duckdb

-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.2,68d7555f68,Andium
PRAGMA version;

INSTALL tpch;
LOAD tpch;
INSTALL httpfs;
LOAD httpfs;

SET memory_limit = '1GB';
ATTACH '[[__DBFOLDER__]]\tpch_encrypted.duckdb' AS encrypted (
    ENCRYPTION_KEY 'asdf',
    ENCRYPTION_CIPHER 'GCM'
);
USE encrypted;

.print CALL dbgen(sf = 1);
CALL dbgen(sf = 1);

ALTER TABLE lineitem
    RENAME TO lineitem1;
CREATE OR REPLACE TABLE lineitem2 AS
    FROM lineitem1;
CREATE OR REPLACE TABLE ans AS
    SELECT l1.* , l2.*
    FROM lineitem1 l1
    JOIN lineitem2 l2 USING (l_orderkey , l_linenumber);

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

ATTACH '[[__DBFOLDER__]]\tpch_unencrypted.duckdb' AS unencrypted;
COPY FROM DATABASE encrypted TO unencrypted;

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

.print To keep track of which databases are encrypted, you can query this by running 'FROM duckdb_databases();':
-- RESULT:database_name,database_oid,path,comment,tags,internal,type,readonly,encrypted,cipher
-- RESULT:unencrypted,2128,C:\Users\charlie\Desktop\sqliteodbc_testsql\csharp_ODBC\bin\Debug\net8.0\db\tpch_unencrypted.duckdb,null,{storage_version=v1.0.0+},false,duckdb,false,false,null
-- RESULT:test,592,c:\users\charlie\desktop\sqliteodbc_testsql\csharp_odbc\bin\debug\net8.0\db\test.duckdb,null,{storage_version=v1.0.0+},false,duckdb,false,false,null
-- RESULT:encrypted,2003,C:\Users\charlie\Desktop\sqliteodbc_testsql\csharp_ODBC\bin\Debug\net8.0\db\tpch_encrypted.duckdb,null,{storage_version=v1.4.0+},false,duckdb,false,true,GCM
-- RESULT:system,0,null,null,{},true,duckdb,false,false,null
-- RESULT:temp,1989,null,null,{},true,duckdb,false,false,null
FROM duckdb_databases();

USE test.main;

DETACH encrypted;
DETACH unencrypted;

.delete [[__DBFOLDER__]]\tpch_encrypted.duckdb
.delete [[__DBFOLDER__]]\tpch_unencrypted.duckdb

.print show SUMMARIZE example...

ATTACH '[[__DBFOLDER__]]\unencrypted.duckdb' AS unencrypted;
CALL dbgen(sf = 10, catalog = 'unencrypted');

ATTACH '[[__DBFOLDER__]]\encrypted.duckdb' AS encrypted (ENCRYPTION_KEY 'asdf');
CREATE TABLE encrypted.lineitem AS FROM unencrypted.lineitem;

SET memory_limit = '200MB';
.timer on

SUMMARIZE unencrypted.lineitem;
SUMMARIZE encrypted.lineitem;
SUMMARIZE encrypted.lineitem;
