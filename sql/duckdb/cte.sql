-- .echo on
-- .timer on
.conn duckdb

WITH AllTables AS (
    SELECT
        table_name
    FROM
        duckdb_tables
),
Tables AS (
    SELECT
        *
    FROM
        AllTables
)
select * from Tables;