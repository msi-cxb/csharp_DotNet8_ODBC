.echo on
-- .timer on
.conn sqlite3-series

-- =============================================================
-- Test: sqlite_extension_functions_series (SQL3-series segment)
-- Description: series extension - generate_series virtual table via connection string
-- Source: sqlite_extension_functions_series in sqliteODBC_tests.vbs (line 2014)
-- Connection: sqlite3-series
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_functions_series SQL3-series connection ===

-- RESULT:value
-- RESULT:0
-- RESULT:5
-- RESULT:10
-- RESULT:15
-- RESULT:20
-- RESULT:25
-- RESULT:30
-- RESULT:35
-- RESULT:40
-- RESULT:45
-- RESULT:50
-- RESULT:55
-- RESULT:60
-- RESULT:65
-- RESULT:70
-- RESULT:75
-- RESULT:80
-- RESULT:85
-- RESULT:90
-- RESULT:95
-- RESULT:100
SELECT * FROM generate_series(0,100,5);

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
