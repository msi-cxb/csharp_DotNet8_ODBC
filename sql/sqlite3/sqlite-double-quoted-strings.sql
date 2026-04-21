.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_double_quoted_strings
-- Description: Double-quoted string literal behavior - SQLITE_DBCONFIG_DQS_DML compatibility
-- Source: sqlite_double_quoted_strings in sqliteODBC_tests.vbs (line 2519)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_double_quoted_strings ===

CREATE TABLE t0(c0 INTEGER);
INSERT INTO t0 VALUES('x');
INSERT INTO t0 VALUES("y");
INSERT INTO t0 VALUES('z');

-- RESULT:cnt
-- RESULT:3
SELECT count(1)  as cnt FROM t0;

-- RESULT:type,name,tbl_name,rootpage,sql
-- RESULT:table,timer,timer,2,CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL)
-- RESULT:table,t0,t0,3,CREATE TABLE t0(c0 INTEGER)
SELECT * FROM sqlite_master WHERE type='table';

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
