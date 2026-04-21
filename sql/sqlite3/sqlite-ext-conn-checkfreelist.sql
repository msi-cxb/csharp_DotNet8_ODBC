.echo on
-- .timer on
.conn sqlite3-checkfreelist

-- =============================================================
-- Test: sqlite_extension_functions_checkfreelist
-- Description: checkfreelist extension - verify database free list integrity
-- Source: sqlite_extension_functions_checkfreelist in sqliteODBC_tests.vbs (line 2137)
-- Connection: sqlite3-checkfreelist
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_functions_checkfreelist ===

-- RESULT:r
-- RESULT:ok
SELECT checkfreelist('main') as r;

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
