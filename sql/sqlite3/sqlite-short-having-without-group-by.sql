.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_havingWithoutGroupBy
-- Description: HAVING without GROUP BY - fixed in 3.39
-- Source: sqlite_havingWithoutGroupBy in sqliteODBC_tests.vbs (line 2876)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_havingWithoutGroupBy ===

-- prior to 3.39 this would result in: Parse error: a GROUP BY clause is required before HAVING
CREATE TABLE t1(a INT);
INSERT INTO t1 VALUES(1),(2),(3);
SELECT sum(a) FROM t1 HAVING sum(a)>0;

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
