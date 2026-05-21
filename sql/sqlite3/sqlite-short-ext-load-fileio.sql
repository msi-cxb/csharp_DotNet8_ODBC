.echo on
-- .timer on
.conn sqlite3

-- .print as of 03.53.00 fileio does not work through ODBC
-- .next

-- =============================================================
-- Test: sqlite_extension_fileio (MEM segment)
-- Description: fileio extension load_extension test - expects Function sequence error
-- Source: sqlite_extension_fileio in sqliteODBC_tests.vbs (line 1297)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_fileio MEM load_extension ===

-- Note: fileio dll does not work with SELECT load_extension(), need to load via connection string
-- Note: expected to fail with: Function sequence error
SELECT load_extension('%APPDATA%\sqlite\64bit\fileio.dll') AS ext_loaded;

SELECT name FROM fsdir('c:\temp');

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
