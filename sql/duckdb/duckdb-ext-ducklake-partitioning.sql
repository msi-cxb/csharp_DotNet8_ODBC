-- https://duckdb.org/2025/05/27/ducklake.html
-- https://duckdb.org/docs/lts/core_extensions/ducklake

.echo on
.timer on
.conn duckdb

-- cleanup any previous ducklake database files
.delete [[__DATAFOLDER__]]\ducklake_data_files
.delete [[__DATAFOLDER__]]\metadata.ducklake

INSTALL ducklake;
LOAD ducklake;

PRAGMA version;

ATTACH 'ducklake:[[__DATAFOLDER__]]/metadata.ducklake' AS my_ducklake (DATA_PATH '[[__DATAFOLDER__]]/ducklake_data_files');

-- RESULT:current_setting('threads')
-- RESULT:6
SELECT current_setting('threads');

-- remove data.parquet to start fresh
.delete [[__DATAFOLDER__]]\flights*.csv
.delete [[__DATAFOLDER__]]\flights

-- get the sample data from https://duckdb.org/data/flights.csv
CREATE OR REPLACE TABLE flights AS FROM 'https://duckdb.org/data/flights.csv';

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:FlightDate,DATE,YES,null,null,null
-- RESULT:UniqueCarrier,VARCHAR,YES,null,null,null
-- RESULT:OriginCityName,VARCHAR,YES,null,null,null
-- RESULT:DestCityName,VARCHAR,YES,null,null,null
DESCRIBE flights;

-- RESULT:FlightDate,UniqueCarrier,OriginCityName,DestCityName
-- RESULT:19880101120000,AA,New York, NY,Los Angeles, CA
-- RESULT:19880102120000,AA,New York, NY,Los Angeles, CA
-- RESULT:19880103120000,AA,New York, NY,Los Angeles, CA
select * from flights;

CREATE OR REPLACE TABLE my_ducklake.flights (FlightDate DATE,UniqueCarrier VARCHAR,OriginCityName VARCHAR,DestCityName VARCHAR);

ALTER TABLE my_ducklake.flights SET PARTITIONED BY (year(FlightDate), month(FlightDate), day(FlightDate));

INSERT INTO my_ducklake.flights SELECT * FROM flights;

FROM my_ducklake.flights;

.print ******************************************************************
FROM ducklake_snapshots('my_ducklake');

.print ******************************************************************
FROM ducklake_table_info('my_ducklake');

.print ******************************************************************
FROM ducklake_cleanup_old_files('my_ducklake');

.print ******************************************************************
-- we can check the files since they change, but we expect 3 files 
-- given partitioning...data_files should look something like
-- C:.
-- \---flights
    -- \---year=1988
        -- \---month=1
            -- +---day=1
            -- |       ducklake-019d73bc-c564-71a3-83f2-a4009b101b37.parquet
            -- |
            -- +---day=2
            -- |       ducklake-019d73bc-c56c-7408-b5b9-b8107e64ca02.parquet
            -- |
            -- \---day=3
                    -- ducklake-019d73bc-c571-7f88-ba83-2e328ddddaaf.parquet-- RESULT:data_file_id,table_id,record_count
-- what we expect...three files each with one table with one record
-- RESULT:data_file_id,table_id,record_count
-- RESULT:0,1,1
-- RESULT:1,1,1
-- RESULT:2,1,1
select data_file_id,table_id,record_count from __ducklake_metadata_my_ducklake.ducklake_data_file;


-- this DOES work
-- files have UUID in them so can't check result
FROM glob('[[__DATAFOLDER__]]/ducklake_data_files/**/*');

FROM '[[__DATAFOLDER__]]/ducklake_data_files/**/*[!delete].parquet';

-- in theory there are no delete parquet files yet...RESULT partial match of result good enough
-- RESULT-ERROR:IO Error: No files found that match the pattern
FROM '[[__DATAFOLDER__]]/ducklake_data_files/**/*delete.parquet';

BEGIN TRANSACTION;
DELETE FROM my_ducklake.flights;

.print ******************************************************************
.print empty
-- RESULT:cnt
-- RESULT:0
SELECT count(1) as cnt FROM my_ducklake.flights;

.print ******************************************************************
.print rollback
ROLLBACK;
-- RESULT:FlightDate,UniqueCarrier,OriginCityName,DestCityName
-- RESULT:19880101120000,AA,New York, NY,Los Angeles, CA
-- RESULT:19880102120000,AA,New York, NY,Los Angeles, CA
-- RESULT:19880103120000,AA,New York, NY,Los Angeles, CA
FROM my_ducklake.flights;

.print ******************************************************************
select database,schema,name from (SHOW ALL TABLES);

.print ******************************************************************
FROM ducklake_table_changes('my_ducklake', 'main', 'flights', 0, 3);

.print ******************************************************************
.print version 3
FROM my_ducklake.flights AT (VERSION => 3);

.print ******************************************************************
-- RESULT:snapshot_id,schema_version,changes,author,commit_message,commit_extra_info
-- RESULT:0,0,{schemas_created=[main]},null,null,null
-- RESULT:1,1,{tables_created=[main.flights]},null,null,null
-- RESULT:2,2,{tables_altered=[1]},null,null,null
-- RESULT:3,2,{tables_inserted_into=[1]},null,null,null
select snapshot_id,schema_version,changes,author,commit_message,commit_extra_info FROM ducklake_snapshots('my_ducklake');

.print ******************************************************************
FROM ducklake_table_info('my_ducklake');

.print ******************************************************************
FROM ducklake_cleanup_old_files('my_ducklake');

.print ******************************************************************
-- RESULT:data_file_id,table_id,record_count
-- RESULT:0,1,1
-- RESULT:1,1,1
-- RESULT:2,1,1
select data_file_id,table_id,record_count from __ducklake_metadata_my_ducklake.ducklake_data_file;

DETACH my_ducklake;