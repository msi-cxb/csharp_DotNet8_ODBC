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

.print ******************************************************************
FROM ducklake_snapshots('my_ducklake');

.print ******************************************************************
FROM ducklake_table_info('my_ducklake');

.print ******************************************************************
FROM ducklake_cleanup_old_files('my_ducklake');

.print ******************************************************************
select * from __ducklake_metadata_my_ducklake.ducklake_data_file;

-- substituting metadata for duckdb_database breaks things (see below)
-- ATTACH 'ducklake:metadata.ducklake' AS my_ducklake;

CREATE OR REPLACE TABLE my_ducklake.demo (foo INTEGER, bar INTEGER);

INSERT INTO my_ducklake.demo VALUES (1,42), (2,43);

-- RESULT:foo,bar
-- RESULT:1,42
-- RESULT:2,43
FROM my_ducklake.demo;

DELETE FROM my_ducklake.demo WHERE bar = 43;

-- RESULT:foo,bar
-- RESULT:1,42
FROM my_ducklake.demo;

-- these are the same
-- results contain time so cannot check results
FROM ducklake_snapshots('my_ducklake');
FROM my_ducklake.snapshots();

-- as mentioned above, using metadata doesn't work...this returns 0 files
-- FROM glob('metadata.ducklake.files/**/*');

-- this DOES work
-- files have UUID in them so can't check result
FROM glob('[[__DATAFOLDER__]]/ducklake_data_files/**/*');

-- RESULT:foo,bar
-- RESULT:1,42
-- RESULT:2,43
FROM '[[__DATAFOLDER__]]/ducklake_data_files/**/*[!delete].parquet';

-- in theory there are no delete parquet files yet
FROM '[[__DATAFOLDER__]]/ducklake_data_files/**/*delete.parquet';

BEGIN TRANSACTION;
DELETE FROM my_ducklake.demo;

.print ******************************************************************
.print empty
FROM my_ducklake.demo;

ROLLBACK;
-- RESULT:foo,bar
-- RESULT:1,42
FROM my_ducklake.demo;

-- RESULT:foo,bar
-- RESULT:1,42
-- RESULT:2,43
FROM my_ducklake.demo AT (VERSION => 2);

.print ******************************************************************
select database,schema,name from (SHOW ALL TABLES);

-- RESULT:snapshot_id,rowid,change_type,foo,bar
-- RESULT:2,0,insert,1,42
-- RESULT:2,1,insert,2,43
-- RESULT:3,1,delete,2,43
FROM ducklake_table_changes('my_ducklake', 'main', 'demo', 2, 3);

.print ******************************************************************
FROM ducklake_snapshots('my_ducklake');

.print ******************************************************************
FROM ducklake_table_info('my_ducklake');

.print ******************************************************************
FROM ducklake_cleanup_old_files('my_ducklake');

.print ******************************************************************
select * from __ducklake_metadata_my_ducklake.ducklake_data_file;

DETACH my_ducklake;