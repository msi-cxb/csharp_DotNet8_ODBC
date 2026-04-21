.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: testDbInventory
-- Description: Loop through SQLite database files in testDBs folder and list tables
-- Source: testDbInventory in sqliteODBC_tests.vbs (line 3498)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === testDbInventory ===

-- Note: This test loops through database files in a folder at runtime.
-- The SQL below demonstrates the schema query used against each database.
SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name;

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
