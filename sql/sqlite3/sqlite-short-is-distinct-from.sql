.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_isDistinctFrom
-- Description: IS DISTINCT FROM / IS NOT DISTINCT FROM operators (new in 3.39)
-- Source: sqlite_isDistinctFrom in sqliteODBC_tests.vbs (line 2854)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_isDistinctFrom ===

-- both should produce 1
SELECT 2 IS TRUE;
SELECT 2 IS NOT DISTINCT FROM TRUE;

-- both should produce 0
SELECT 2 IS NOT TRUE;
SELECT 2 IS DISTINCT FROM TRUE;

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
