.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: getTableInfoDetails
-- Description: List all columns in a SQLite database using pragma_table_info
-- Source: getTableInfoDetails in sqliteODBC_tests.vbs (line 4513)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === getTableInfoDetails ===

-- Ensure test_table exists
DROP TABLE IF EXISTS test_table;
CREATE TABLE test_table (
    id INTEGER PRIMARY KEY,
    myField_1 TEXT,
    myField_2 TEXT,
    myField_3 TEXT,
    myField_4 TEXT,
    myField_5 TEXT
);
INSERT INTO test_table (id, myField_1, myField_2, myField_3, myField_4, myField_5)
WITH RECURSIVE gen(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM gen WHERE x < 5)
SELECT x, 'myField_1', 'myField_2', 'myField_3', 'myField_4', 'myField_5' FROM gen;

SELECT * FROM sqlite_master;

.print === first recipe: full pragma_table_info details ===

SELECT
    sqlite_master.name AS table_name,
    table_info.*
FROM
    sqlite_master
    JOIN pragma_table_info(sqlite_master.name) AS table_info
ORDER BY
    sqlite_master.name;

.print === second recipe: simple table and column names ===

SELECT
    m.name AS tableName,
    p.name AS columnName
FROM
    sqlite_master m
    LEFT OUTER JOIN pragma_table_info((m.name)) p ON m.name <> p.name
WHERE
    m.type IN ('table', 'view')
    AND m.name NOT LIKE 'sqlite_%'
ORDER BY
    tableName,
    columnName;

INSERT INTO timer VALUES('file', 'the end', unixepoch('now', 'subsec'));

.print time results
SELECT
    task_name,
    note,
    strftime('%H:%M:%f', ts_msec_delta, 'unixepoch') AS delta
FROM (
    SELECT *,
        ts_msec - LAG(ts_msec, 1) OVER (PARTITION BY task_name ORDER BY ts_msec) AS ts_msec_delta
    FROM (SELECT *, row_number() OVER () AS rowid FROM timer)
) WHERE ts_msec_delta IS NOT NULL ORDER BY rowid;
