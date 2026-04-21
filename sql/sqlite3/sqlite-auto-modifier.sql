.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_autoModifier
-- Description: auto modifier interprets value based on magnitude (added 3.38.0)
-- Source: sqlite_autoModifier in sqliteODBC_tests.vbs (line 2914)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_autoModifier ===

-- auto interprets value based on magnitude of input
SELECT datetime(2459759.67224309,'auto') AS j;
SELECT datetime(1092941466, 'auto') AS u;

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
