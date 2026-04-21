.echo on
-- .timer on
.conn sqlite3-sqlfcmp

-- =============================================================
-- Test: sqlite_sqlfcmp (SQL3-sqlfcmp segment)
-- Description: sqlfcmp extension - ULP arithmetic, sigdigits, format functions via connection string
-- Source: sqlite_sqlfcmp in sqliteODBC_tests.vbs (line 1014)
-- Connection: sqlite3-sqlfcmp
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_sqlfcmp SQL3-sqlfcmp connection ===

DROP TABLE IF EXISTS t;
CREATE TABLE t(c REAL);
INSERT INTO t VALUES(100-5*ulp(100));
INSERT INTO t VALUES(100-4*ulp(100));
INSERT INTO t VALUES(100-3*ulp(100));
INSERT INTO t VALUES(100-2*ulp(100));
INSERT INTO t VALUES(100-1*ulp(100));
INSERT INTO t VALUES(100-0*ulp(100));
INSERT INTO t VALUES(100+1*ulp(100));
INSERT INTO t VALUES(100+2*ulp(100));
INSERT INTO t VALUES(100+3*ulp(100));
INSERT INTO t VALUES(100+4*ulp(100));
INSERT INTO t VALUES(100+5*ulp(100));

.print === format ULP values ===

-- Note: expects 11 rows
-- RESULT:v
-- RESULT:99.9999999999999289
-- RESULT:99.9999999999999432
-- RESULT:99.9999999999999574
-- RESULT:99.9999999999999716
-- RESULT:99.9999999999999858
-- RESULT:100.0
-- RESULT:100.0000000000000142
-- RESULT:100.0000000000000284
-- RESULT:100.0000000000000426
-- RESULT:100.0000000000000568
-- RESULT:100.0000000000000711
SELECT format('%!.30f', c) as v FROM t;

.print === sigdigits positive ===

-- RESULT:sigdigits
-- RESULT:100
SELECT sigdigits(100.000001,8) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:100
SELECT sigdigits(100.0000049,8) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:100
SELECT sigdigits(100.0000050,8) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:100.00001
SELECT sigdigits(100.0000051,8) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:100.00001
SELECT sigdigits(100.000009,8) AS sigdigits;

.print === sigdigits negative ===

-- RESULT:sigdigits
-- RESULT:-100
SELECT sigdigits(-100.000001,8) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:-100
SELECT sigdigits(-100.0000049,8) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:-100
SELECT sigdigits(-100.0000050,8) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:-100.00001
SELECT sigdigits(-100.0000051,8) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:-100.00001
SELECT sigdigits(-100.000009,8) AS sigdigits;

.print === sigdigits precision ===

-- RESULT:sigdigits
-- RESULT:100.0000000001
SELECT sigdigits(100.0000000001,13) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:100.00000000001
SELECT sigdigits(100.00000000001,14) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:100.00000000001
SELECT sigdigits(100.00000000001) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:100
SELECT sigdigits(100.000000000001,15) AS sigdigits;
-- RESULT:sigdigits
-- RESULT:100
SELECT sigdigits(100.000000000001) AS sigdigits;

.print === total and format ===

-- RESULT:v
-- RESULT:1100
SELECT total(c) as v FROM t;
-- RESULT:fmt
-- RESULT:1100.0
SELECT format('%!.30f', total(c)) AS fmt FROM t;

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
