.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_strictTable
-- Description: STRICT tables - type enforcement added in 3.37
-- Source: sqlite_strictTable in sqliteODBC_tests.vbs (line 2942)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === strict_table scenario 1: without STRICT ===

CREATE TABLE t1(a TEXT);
INSERT INTO t1 VALUES('000123');
INSERT INTO t1 VALUES(123);
SELECT typeof(a), quote(a) FROM t1;
CREATE TABLE t2(a INTEGER);
INSERT INTO t2 VALUES('000123');
INSERT INTO t2 VALUES(123);
SELECT typeof(a), quote(a) FROM t2;

.print === strict_table scenario 2: with STRICT ===

DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS t3;
DROP TABLE IF EXISTS t4;
DROP TABLE IF EXISTS t5;
DROP TABLE IF EXISTS t6;
DROP TABLE IF EXISTS t7;
DROP TABLE IF EXISTS t8;
DROP TABLE IF EXISTS t9;

CREATE TABLE t1(a TEXT) STRICT;
INSERT INTO t1 VALUES('000123');
INSERT INTO t1 VALUES(123);
INSERT INTO t1 VALUES('eeeee');
SELECT typeof(a), quote(a) FROM t1;

CREATE TABLE t2(a INTEGER) STRICT;
INSERT INTO t2 VALUES('000123');
INSERT INTO t2 VALUES(123);
-- Note: attempting to insert string into strict integer will fail
INSERT INTO t1 VALUES('eeeee');
SELECT typeof(a), quote(a) FROM t2;

-- Note: expected to fail with: table t3 has column(s) without datatype
-- RESULT-ERROR:missing datatype for t3.a (1) (source: sqlite3odbc.dll)
CREATE TABLE t3(a) STRICT;

CREATE TABLE t4(a);
INSERT INTO t4 VALUES('000123');
INSERT INTO t4 VALUES(123);
SELECT typeof(a), quote(a) FROM t4;

CREATE TABLE t5(a VARCHAR);
-- Note: expected to fail with: unknown datatype for t6.a: "VARCHAR"
-- RESULT-ERROR:unknown datatype for t6.a: "VARCHAR" (1) (source: sqlite3odbc.dll)
CREATE TABLE t6(a VARCHAR) STRICT;
CREATE TABLE t7(d DOUBLE);
-- Note: expected to fail with: unknown datatype for t8.d: "DOUBLE"
-- RESULT-ERROR:unknown datatype for t8.d: "DOUBLE" (1) (source: sqlite3odbc.dll)
CREATE TABLE t8(d DOUBLE) STRICT;
CREATE TABLE t9(i INT, ii INTEGER, r REAL, t TEXT, b BLOB, a ANY) STRICT;

.print === strict_table scenario 3: ANY in STRICT preserves data ===

DROP TABLE IF EXISTS t1;
CREATE TABLE t1(a ANY) STRICT;
INSERT INTO t1 VALUES('000123');
SELECT typeof(a), quote(a) FROM t1;

.print === strict_table scenario 4: ANY in non-STRICT converts numbers ===

DROP TABLE IF EXISTS t1;
CREATE TABLE t1(a ANY);
INSERT INTO t1 VALUES('000123');
SELECT typeof(a), quote(a) FROM t1;

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
