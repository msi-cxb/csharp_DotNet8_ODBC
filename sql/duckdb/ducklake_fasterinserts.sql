-- https://duckdb.org/2025/09/17/ducklake-03.html

.echo on
.timer on
.conn duckdb

INSTALL ducklake;
LOAD ducklake;

ATTACH 'ducklake:my_ducklake.ducklake' AS ducklake;

CREATE TABLE sample_table AS SELECT * FROM range(1_000_000_000);

select count(1) as cnt from sample_table;

CALL ducklake.set_option('per_thread_output', false);

CREATE TABLE slow_copy AS SELECT * FROM sample_table;

CALL ducklake.set_option('per_thread_output', true);

CREATE TABLE fast_copy AS SELECT * FROM sample_table;
