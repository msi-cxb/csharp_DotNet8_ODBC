-- https://duckdb.org/2025/05/27/ducklake.html

-- .echo on
-- .timer on
.conn duckdb

-- cleanup any previous ducklake database files
.system del /Q duckdb_database.ducklake
-- .system del /Q metadata.ducklake
.system rmdir /Q /S duckdb_database.ducklake.files

-- .quit

INSTALL ducklake;
LOAD ducklake;

-- version that works
-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.0,b8a06e4a22,Andium
PRAGMA version;

-- -- use a DuckDB database "duckdb_database.ducklake" as the catalog database, the data path defaults to duckdb_database.ducklake.files
ATTACH 'ducklake:duckdb_database.ducklake' AS my_ducklake;

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
FROM glob('duckdb_database.ducklake.files/**/*');

-- RESULT:foo,bar
-- RESULT:1,42
-- RESULT:2,43
FROM 'duckdb_database.ducklake.files/**/*[!delete].parquet';

-- in theory there are no delete parquet files yet
FROM 'duckdb_database.ducklake.files/**/*delete.parquet';

BEGIN TRANSACTION;
DELETE FROM my_ducklake.demo;
FROM my_ducklake.demo;

ROLLBACK;
-- RESULT:foo,bar
-- RESULT:1,42
FROM my_ducklake.demo;

-- RESULT:foo,bar
-- RESULT:1,42
-- RESULT:2,43
FROM my_ducklake.demo AT (VERSION => 2);

-- RESULT:snapshot_id,rowid,change_type,foo,bar
-- RESULT:2,0,insert,1,42
-- RESULT:2,1,insert,2,43
-- RESULT:3,1,delete,2,43
FROM ducklake_table_changes('my_ducklake', 'main', 'demo', 2, 3);

DETACH my_ducklake;