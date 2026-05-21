.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_extension_functions_wholenumber (MEM segment)
-- Description: wholenumber extension - virtual table for integer sequences via load_extension
-- Source: sqlite_extension_functions_wholenumber in sqliteODBC_tests.vbs (line 1763)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_functions_wholenumber MEM load_extension ===

SELECT load_extension('%APPDATA%\sqlite\64bit\wholenumber.dll') AS loaded;

DROP TABLE IF EXISTS nums;
CREATE VIRTUAL TABLE nums USING wholenumber;

-- Note: expects 9 rows
-- RESULT:value
-- RESULT:1
-- RESULT:2
-- RESULT:3
-- RESULT:4
-- RESULT:5
-- RESULT:6
-- RESULT:7
-- RESULT:8
-- RESULT:9
SELECT value FROM nums WHERE value<10;

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
