.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: SQLite Version
-- Description: Verifies the installed SQLite version and source
--              ID match the expected build. Confirms the ODBC
--              driver is connected to the correct SQLite library.
-- Source: sqlite_version() in sqliteODBC_tests.vbs (line 522)
-- Connection: sqlite3 (in-memory equivalent)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === SQLite version and source ID ===

SELECT sqlite_version() AS vers, sqlite_source_id() AS srcId;

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
