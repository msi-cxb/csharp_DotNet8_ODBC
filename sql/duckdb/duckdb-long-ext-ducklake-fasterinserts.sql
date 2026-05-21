-- https://duckdb.org/2025/09/17/ducklake-03.html

-- In the following benchmark we did find ~25% improvement when enabling per_thread_output
-- through odbc this is 4-5 times slower
-- also both options took same amount of time 20 sec.

.echo on
.timer on
.conn duckdb

-- cleanup any previous ducklake database files
.delete [[__DATAFOLDER__]]\ducklake_data_files
.delete [[__DATAFOLDER__]]\metadata.ducklake

INSTALL ducklake;
LOAD ducklake;

ATTACH 'ducklake:[[__DATAFOLDER__]]/metadata.ducklake' AS my_ducklake (DATA_PATH '[[__DATAFOLDER__]]/ducklake_data_files');

FROM my_ducklake.options();

CREATE TABLE sample_table AS SELECT * FROM range(1_000_000_000);

select count(1) as cnt from sample_table;

CALL my_ducklake.set_option('per_thread_output', false);

CREATE TABLE my_ducklake.slow_copy AS SELECT * FROM sample_table;

CALL my_ducklake.set_option('per_thread_output', true);

CREATE TABLE my_ducklake.fast_copy AS SELECT * FROM sample_table;

DETACH my_ducklake;
