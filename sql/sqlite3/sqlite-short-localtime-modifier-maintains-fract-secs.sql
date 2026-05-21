.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_localtimeModifierMaintainsFractSecs
-- Description: localtime modifier preserves fractional seconds (fixed in 3.38.1)
-- Source: sqlite_localtimeModifierMaintainsFractSecs in sqliteODBC_tests.vbs (line 2890)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_localtimeModifierMaintainsFractSecs ===

-- output should include fractional seconds
SELECT strftime('%Y-%m-%d %H:%M:%f', 1.234, 'unixepoch', 'localtime') AS r;

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
