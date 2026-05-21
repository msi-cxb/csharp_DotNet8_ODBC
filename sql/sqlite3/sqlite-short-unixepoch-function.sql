.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_unixepochFunction
-- Description: unixepoch() function (added 3.38.0)
-- Source: sqlite_unixepochFunction in sqliteODBC_tests.vbs (line 2901)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_unixepochFunction ===

SELECT unixepoch() AS e;

-- t1 and t2 will both be integers; t2 ignores fractional seconds as designed
SELECT unixepoch('2004-01-01 02:34:56') AS t1, unixepoch('2004-01-01 02:34:56.789') AS t2;

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
