.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: getTableInfoSimple
-- Description: Get table schema info using PRAGMA table_info and pragma_table_info
-- Source: getTableInfoSimple in sqliteODBC_tests.vbs (line 4486)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === getTableInfoSimple ===

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

SELECT * FROM test_table LIMIT 3;

PRAGMA table_info(test_table);

SELECT * FROM pragma_table_info('test_table') WHERE name LIKE '%MyField%';

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
