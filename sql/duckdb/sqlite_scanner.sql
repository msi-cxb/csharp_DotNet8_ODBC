-- .echo on
-- .timer on
.conn duckdb

PRAGMA version;

-- RESULT:current_setting('threads')
-- RESULT:6
SELECT current_setting('threads');

-- remove data.parquet to start fresh
.system del /Q [[__DATAFOLDER__]]\data.parquet > nul 2>&1

.print install sqlite_scanner from local extensions repo (note these are signed copies from core)
FORCE INSTALL sqlite_scanner from '.\local_extensions';
-- INSTALL sqlite_scanner;
LOAD sqlite_scanner;

-- RESULT:extension_name,loaded,installed,install_path,description,aliases,extension_version,install_mode,installed_from
-- RESULT:sqlite_scanner,true,true,C:\Users\charlie\.duckdb\extensions\v1.3.2\windows_amd64\sqlite_scanner.duckdb_extension,Adds support for reading and writing SQLite database files,[sqlite, sqlite3],ed38d77,REPOSITORY,.\local_extensions
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

-- copy sqlite_db.tbl to data.parquet
COPY sqlite_db.tbl TO '[[__DATAFOLDER__]]/data.parquet';

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:id,BIGINT,YES,null,null,null
-- RESULT:name,VARCHAR,YES,null,null,null
DESCRIBE SELECT * FROM '[[__DATAFOLDER__]]/data.parquet';

-- RESULT:file_name,name,type,type_length,repetition_type,num_children,converted_type,scale,precision,field_id,logical_type
-- RESULT:H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data/data.parquet,duckdb_schema,null,null,REQUIRED,2,null,null,null,null,null
-- RESULT:H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data/data.parquet,id,INT64,null,OPTIONAL,null,INT_64,null,null,null,null
-- RESULT:H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data/data.parquet,name,BYTE_ARRAY,null,OPTIONAL,null,UTF8,null,null,null,null
SELECT * FROM parquet_schema('[[__DATAFOLDER__]]/data.parquet');

-- RESULT:file_name,row_group_id,row_group_num_rows,row_group_num_columns,row_group_bytes,column_id,file_offset,num_values,path_in_schema,type,stats_min,stats_max,stats_null_count,stats_distinct_count,stats_min_value,stats_max_value,compression,encodings,index_page_offset,dictionary_page_offset,data_page_offset,total_compressed_size,total_uncompressed_size,key_value_metadata,bloom_filter_offset,bloom_filter_length,min_is_exact,max_is_exact
-- RESULT:H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data/data.parquet,0,1,2,96,0,0,1,id,INT64,42,42,0,1,42,42,SNAPPY,RLE_DICTIONARY,null,4,27,51,47,{},108,47,true,true
-- RESULT:H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data/data.parquet,0,1,2,96,1,0,1,name,BYTE_ARRAY,DuckDB,DuckDB,0,1,DuckDB,DuckDB,SNAPPY,RLE_DICTIONARY,null,55,80,53,49,{},155,47,true,true
SELECT * FROM parquet_metadata('[[__DATAFOLDER__]]/data.parquet');

-- RESULT:file_name,created_by,num_rows,num_row_groups,format_version,encryption_algorithm,footer_signing_key_metadata
-- RESULT:H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data/data.parquet,DuckDB version v1.3.2 (build 0b83e5d2f6),1,1,1,null,null
SELECT * FROM parquet_file_metadata('[[__DATAFOLDER__]]/data.parquet');

-- exports sakila to parquet files
-- EXPORT DATABASE '[[__DATAFOLDER__]]' (FORMAT parquet);

-- RESULT:id,name
-- RESULT:42,DuckDB
SELECT * FROM '[[__DATAFOLDER__]]/data.parquet';

-- COPY performs an insert on existing table...hence 2 records in next select
COPY sqlite_db.tbl FROM '[[__DATAFOLDER__]]/data.parquet';

-- RESULT:id,name
-- RESULT:42,DuckDB
-- RESULT:42,DuckDB
SELECT * from sqlite_db.tbl;

-- update both records
UPDATE sqlite_db.tbl SET name = 'Woohoo' WHERE id = 42;

-- RESULT:id,name
-- RESULT:42,Woohoo
-- RESULT:42,Woohoo
SELECT * from sqlite_db.tbl;

-- deletes both records resulting in empty table
DELETE FROM sqlite_db.tbl WHERE id = 42;

--empty
SELECT * from sqlite_db.tbl;

ALTER TABLE sqlite_db.tbl ADD COLUMN k INTEGER;
INSERT INTO sqlite_db.tbl (id, name, k) VALUES (42, 'DuckDB', -666);
INSERT INTO sqlite_db.tbl VALUES (42, 'DuckDB', -777);

-- RESULT:id,name,k
-- RESULT:42,DuckDB,-666
-- RESULT:42,DuckDB,-777
SELECT * from sqlite_db.tbl;

.print you can create sqlite views
CREATE OR REPLACE VIEW sqlite_db.v1 AS SELECT 42;

-- RESULT:42
-- RESULT:42
select * from sqlite_db.v1;

CREATE OR REPLACE TABLE sqlite_db.tmp (i INTEGER);

BEGIN;
INSERT INTO sqlite_db.tmp VALUES (42);

-- RESULT:i
-- RESULT:42
SELECT * FROM sqlite_db.tmp;

ROLLBACK;

-- empty
SELECT * FROM sqlite_db.tmp;

BEGIN;
INSERT INTO sqlite_db.tmp VALUES (42),(43),(44),(45),(46);
INSERT INTO sqlite_db.tmp VALUES (52),(53),(54),(55),(56);
INSERT INTO sqlite_db.tmp VALUES (62),(63),(64),(65),(66);
COMMIT;


-- one way to copy table from sqlite to duckdb is to
-- export sqlite to parquet and then import parquet to duckdb
-- however there is a better way...

-- copy data from sqlite to duckdb via parquet
-- COPY sqlite_db.tbl TO '[[__DATAFOLDER__]]/tbl.parquet';
-- CREATE OR REPLACE TABLE tbl AS SELECT * FROM '[[__DATAFOLDER__]]/tbl.parquet';

-- RESULT:id,name,k
-- RESULT:42,DuckDB,-666
-- RESULT:42,DuckDB,-777
-- select * from tbl;

-- COPY sqlite_db.tmp TO '[[__DATAFOLDER__]]/tmp.parquet';
-- CREATE OR REPLACE TABLE tmp AS SELECT * FROM '[[__DATAFOLDER__]]/tmp.parquet';

-- select * from tmp;

.print ********************************************************
.print you can copy tables directly from sqlite to duckdb
.print ********************************************************
CREATE OR REPLACE TABLE tmp AS FROM sqlite_db.tmp;

.print ********************************************************
.print you can copy tables directly from duckdb to sqlite
.print ********************************************************
CREATE OR REPLACE TABLE sqlite_db.new_tmp AS FROM tmp;

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:i,BIGINT,YES,null,null,null
DESCRIBE sqlite_db.tmp;

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:i,BIGINT,YES,null,null,null
DESCRIBE tmp;

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:i,BIGINT,YES,null,null,null
DESCRIBE sqlite_db.new_tmp;

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
SELECT * FROM sqlite_db.tmp order by i;

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
select * from tmp order by i;

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
select * from sqlite_db.new_tmp order by i;
