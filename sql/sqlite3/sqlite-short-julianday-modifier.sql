.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_juliandayModifier
-- Description: julianday modifier forces julian day interpretation (added 3.38.0)
-- Source: sqlite_juliandayModifier in sqliteODBC_tests.vbs (line 2926)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_juliandayModifier ===

-- default is to interpret number as julian day
SELECT datetime(2459759.67224309) AS j;
-- force number to be interpreted as unixepoch
SELECT datetime(1092941466, 'unixepoch') AS u;
-- force number to be interpreted as julianday
SELECT datetime(2459759.67224309,'julianday') AS j;
SELECT datetime(2459759,'julianday') AS j;

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
