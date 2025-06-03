.echo ON
.timer ON

-- [[__DBFOLDER__]]
-- [[__DATAFOLDER__]]

PRAGMA version;

-- RESULT:current_setting('threads')
-- RESULT:6
SELECT current_setting('threads');

.print install sqlite_scanner from local extensions repo (note these are signed copies from core)
FORCE INSTALL sqlite_scanner from '.\local_extensions';
-- INSTALL sqlite_scanner;
LOAD sqlite_scanner;

-- RESULT:extension_name,installed,description
-- RESULT:autocomplete,false,Adds support for autocomplete in the shell
-- RESULT:aws,false,Provides features that depend on the AWS SDK
-- RESULT:azure,false,Adds a filesystem abstraction for Azure blob storage to DuckDB
-- RESULT:core_functions,true,Core function library
-- RESULT:delta,false,Adds support for Delta Lake
-- RESULT:excel,false,Adds support for Excel-like format strings
-- RESULT:fts,true,Adds support for Full-Text Search Indexes
-- RESULT:httpfs,false,Adds support for reading and writing files over a HTTP(S) connection
-- RESULT:iceberg,false,Adds support for Apache Iceberg
-- RESULT:icu,true,Adds support for time zones and collations using the ICU library
-- RESULT:inet,false,Adds support for IP-related data types and functions
-- RESULT:jemalloc,false,Overwrites system allocator with JEMalloc
-- RESULT:json,true,Adds support for JSON operations
-- RESULT:motherduck,false,Enables motherduck integration with the system
-- RESULT:mysql_scanner,false,Adds support for connecting to a MySQL database
-- RESULT:parquet,true,Adds support for reading and writing parquet files
-- RESULT:postgres_scanner,false,Adds support for connecting to a Postgres database
-- RESULT:spatial,true,Geospatial extension that adds support for working with spatial data and functions
-- RESULT:sqlite_scanner,true,Adds support for reading and writing SQLite database files
-- RESULT:tpcds,true,Adds TPC-DS data generation and query support
-- RESULT:tpch,true,Adds TPC-H data generation and query support
-- RESULT:ui,false,Adds local UI for DuckDB
-- RESULT:vss,false,Adds indexing support to accelerate Vector Similarity Search
SELECT extension_name, installed, description FROM duckdb_extensions();

-- RESULT:extension_name,loaded,installed,install_path,description,aliases,extension_version,install_mode,installed_from
-- RESULT:sqlite_scanner,true,true,C:\Users\charlie\.duckdb\extensions\fda0ba6a7a\windows_amd64\sqlite_scanner.duckdb_extension,Adds support for reading and writing SQLite database files,[sqlite, sqlite3],66a5fa2,REPOSITORY,core
select * from duckdb_extensions() where extension_name = 'sqlite_scanner';

ATTACH 'M:\Files\databases\sqlite_scanner_db\sakila.db' AS sakila (TYPE sqlite);

USE sakila;

-- RESULT:category_name,revenue
-- RESULT:Sports,5314.209999999848
-- RESULT:Sci-Fi,4756.97999999987
-- RESULT:Animation,4656.299999999864
-- RESULT:Drama,4587.389999999876
-- RESULT:Comedy,4383.579999999895
SELECT cat.name category_name, 
       Sum(Ifnull(pay.amount, 0)) revenue 
FROM   category cat 
       LEFT JOIN film_category flm_cat 
              ON cat.category_id = flm_cat.category_id 
       LEFT JOIN film fil 
              ON flm_cat.film_id = fil.film_id 
       LEFT JOIN inventory inv 
              ON fil.film_id = inv.film_id 
       LEFT JOIN rental ren 
              ON inv.inventory_id = ren.inventory_id 
       LEFT JOIN payment pay 
              ON ren.rental_id = pay.rental_id 
GROUP  BY cat.name 
ORDER  BY revenue DESC 
LIMIT  5;

ATTACH '[[__DBFOLDER__]]/new_sqlite_database.db' AS sqlite_db (TYPE sqlite);

DROP TABLE IF EXISTS sqlite_db.tbl;

CREATE TABLE sqlite_db.tbl (id INTEGER, name VARCHAR);

INSERT INTO sqlite_db.tbl VALUES (42, 'DuckDB');

-- RESULT:id,name
-- RESULT:42,DuckDB
SELECT * FROM sqlite_db.tbl;

COPY sqlite_db.tbl TO '[[__DATAFOLDER__]]/data.parquet';

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:id,BIGINT,YES,null,null,null
-- RESULT:name,VARCHAR,YES,null,null,null
DESCRIBE SELECT * FROM '[[__DATAFOLDER__]]/data.parquet';

-- RESULT:file_name,name,type,type_length,repetition_type,num_children,converted_type,scale,precision,field_id,logical_type
-- RESULT:H:\csharp_DotNet8_ODBC\data/data.parquet,duckdb_schema,null,null,REQUIRED,2,null,null,null,null,null
-- RESULT:H:\csharp_DotNet8_ODBC\data/data.parquet,id,INT64,null,OPTIONAL,null,INT_64,null,null,null,null
-- RESULT:H:\csharp_DotNet8_ODBC\data/data.parquet,name,BYTE_ARRAY,null,OPTIONAL,null,UTF8,null,null,null,null
SELECT * FROM parquet_schema('[[__DATAFOLDER__]]/data.parquet');

-- RESULT:file_name,row_group_id,row_group_num_rows,row_group_num_columns,row_group_bytes,column_id,file_offset,num_values,path_in_schema,type,stats_min,stats_max,stats_null_count,stats_distinct_count,stats_min_value,stats_max_value,compression,encodings,index_page_offset,dictionary_page_offset,data_page_offset,total_compressed_size,total_uncompressed_size,key_value_metadata,bloom_filter_offset,bloom_filter_length,min_is_exact,max_is_exact
-- RESULT:H:\csharp_DotNet8_ODBC\data/data.parquet,0,1,2,96,0,0,1,id,INT64,42,42,0,1,42,42,SNAPPY,RLE_DICTIONARY,null,4,27,51,47,{},108,47,true,true
-- RESULT:H:\csharp_DotNet8_ODBC\data/data.parquet,0,1,2,96,1,0,1,name,BYTE_ARRAY,DuckDB,DuckDB,0,1,DuckDB,DuckDB,SNAPPY,RLE_DICTIONARY,null,55,80,53,49,{},155,47,true,true
SELECT * FROM parquet_metadata('[[__DATAFOLDER__]]/data.parquet');

-- RESULT:file_name,created_by,num_rows,num_row_groups,format_version,encryption_algorithm,footer_signing_key_metadata
-- RESULT:H:\csharp_DotNet8_ODBC\data/data.parquet,DuckDB version v1.3.0-dev3365 (build fda0ba6a7a),1,1,1,null,null
SELECT * FROM parquet_file_metadata('[[__DATAFOLDER__]]/data.parquet');

EXPORT DATABASE '[[__DATAFOLDER__]]' (FORMAT parquet);

SELECT * FROM '[[__DATAFOLDER__]]/data.parquet';

COPY sqlite_db.tbl FROM '[[__DATAFOLDER__]]/data.parquet';

-- RESULT:id,name
-- RESULT:42,DuckDB
-- RESULT:42,DuckDB
SELECT * from sqlite_db.tbl;

UPDATE sqlite_db.tbl SET name = 'Woohoo' WHERE id = 42;

-- RESULT:id,name
-- RESULT:42,Woohoo
-- RESULT:42,Woohoo
SELECT * from sqlite_db.tbl;

DELETE FROM sqlite_db.tbl WHERE id = 42;

SELECT * from sqlite_db.tbl;

ALTER TABLE sqlite_db.tbl ADD COLUMN k INTEGER;
INSERT INTO sqlite_db.tbl (id, name, k) VALUES (42, 'DuckDB', -666);
INSERT INTO sqlite_db.tbl VALUES (42, 'DuckDB', -777);

SELECT * from sqlite_db.tbl;

DROP TABLE sqlite_db.tbl;

CREATE OR REPLACE VIEW sqlite_db.v1 AS SELECT 42;

CREATE OR REPLACE TABLE sqlite_db.tmp (i INTEGER);

BEGIN;
INSERT INTO sqlite_db.tmp VALUES (42);

-- RESULT:i
-- RESULT:42
SELECT * FROM sqlite_db.tmp;

ROLLBACK;

SELECT * FROM sqlite_db.tmp;

BEGIN;
INSERT INTO sqlite_db.tmp VALUES (42),(43),(44),(45),(46);
INSERT INTO sqlite_db.tmp VALUES (52),(53),(54),(55),(56);
INSERT INTO sqlite_db.tmp VALUES (62),(63),(64),(65),(66);
COMMIT;

-- RESULT:i
-- RESULT:42
-- RESULT:43
-- RESULT:44
-- RESULT:45
-- RESULT:46
-- RESULT:52
-- RESULT:53
-- RESULT:54
-- RESULT:55
-- RESULT:56
-- RESULT:62
-- RESULT:63
-- RESULT:64
-- RESULT:65
-- RESULT:66
SELECT * FROM sqlite_db.tmp;

.print build a large_table in attached sqlite3 database file
CREATE OR REPLACE TABLE sqlite_db.large_table (
    id BIGINT,
    hash UINT64,
    rand DOUBLE,
    value DOUBLE
);

SELECT SETSEED(0.42);

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
-- RESULT:3,8131803788478518982,1,0.6736244023239688
-- RESULT:4,8535942711051191036,1,0.6039073183711521
-- RESULT:5,4244145009296420692,1,0.8896556698196139
-- RESULT:6,8888402906861678137,1,0.5964760979082881
-- RESULT:7,8736873150706563146,1,0.5162138718876562
-- RESULT:8,14111048738911615569,1,0.7617043067030548
-- RESULT:9,17319221087726947361,1,0.2110601959096939
-- RESULT:10,5527453332085100658,1,0.7431629726220786
-- RESULT:11,6770051751173734325,1,0.38431060686081925
select * from sqlite_db.large_table order by id limit 10;

.print build a large_table in duckdb database file
CREATE OR REPLACE TABLE large_table (
    id BIGINT,
    hash UINT64,
    rand DOUBLE,
    value DOUBLE
);

SELECT SETSEED(0.42);

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
-- RESULT:3,8131803788478518982,1,0.6736244023239688
-- RESULT:4,8535942711051191036,1,0.6039073183711521
-- RESULT:5,4244145009296420692,1,0.8896556698196139
-- RESULT:6,8888402906861678137,1,0.5964760979082881
-- RESULT:7,8736873150706563146,1,0.5162138718876562
-- RESULT:8,14111048738911615569,1,0.7617043067030548
-- RESULT:9,17319221087726947361,1,0.2110601959096939
-- RESULT:10,5527453332085100658,1,0.7431629726220786
-- RESULT:11,6770051751173734325,1,0.38431060686081925
select * from large_table order by id limit 10;
