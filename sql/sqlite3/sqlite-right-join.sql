.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_right_join
-- Description: RIGHT JOIN and FULL OUTER JOIN edge cases from SQLite forum issues
-- Source: sqlite_right_join in sqliteODBC_tests.vbs (line 2736)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === right_join scenario 1 ===

DROP TABLE IF EXISTS t0;
DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS t3;
CREATE TABLE t0(c0 INTEGER);
INSERT INTO t0 VALUES('x');
CREATE TABLE t1(c0 INTEGER);
INSERT INTO t1 VALUES('y');
CREATE TABLE t2(c0, c1 NOT NULL);
INSERT INTO t2 VALUES('a', 'b');
CREATE TABLE t3(c0 INTEGER);
INSERT INTO t3 VALUES('c');
SELECT * FROM t3 LEFT OUTER JOIN t2 INNER JOIN t0 ON t2.c1 RIGHT OUTER JOIN t1 ON t2.c0;
SELECT * FROM t3 LEFT OUTER JOIN t2 INNER JOIN t0 ON t2.c1 RIGHT OUTER JOIN t1 ON t2.c0 WHERE (((t2.c1) ISNULL));
SELECT (((t2.c1) ISNULL) IS TRUE) FROM t3 LEFT OUTER JOIN t2 INNER JOIN t0 ON t2.c1 RIGHT OUTER JOIN t1 ON t2.c0;

.print === right_join scenario 2 ===

DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS t3;
CREATE TABLE t1 (c0, c1);
INSERT INTO t1(c0) VALUES (2);
CREATE TABLE t2 (c0);
CREATE INDEX i0 ON t2 (c0) WHERE c0;
CREATE TABLE t3 (c0);
INSERT INTO t3 VALUES (1);
SELECT * FROM t2 RIGHT OUTER JOIN t3 ON t3.c0 LEFT OUTER JOIN t1 ON t2.c0 WHERE t1.c0;
SELECT (t1.c0 IS TRUE) FROM t2 RIGHT OUTER JOIN t3 ON t3.c0 LEFT OUTER JOIN t1 ON t2.c0;

.print === right_join scenario 3 ===

DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS t3;
CREATE TABLE t1(a INT);
CREATE TABLE t2(b INT);
CREATE TABLE t3(c INTEGER PRIMARY KEY, d INT);
CREATE INDEX t3d ON t3(d);
INSERT INTO t3 VALUES(0, 0);
-- RESULT-ERROR:ON clause references tables to its right (1) (source: sqlite3odbc.dll)
SELECT * FROM t1 JOIN t2 ON d>b RIGHT JOIN t3 ON true WHERE +d = 0;
-- RESULT-ERROR:ON clause references tables to its right (1) (source: sqlite3odbc.dll)
SELECT * FROM t1 JOIN t2 ON d>b RIGHT JOIN t3 ON true WHERE d = 0;

.print === right_join scenario 4 ===

DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS t3;
CREATE TABLE t1(a INT,b BOOLEAN);
CREATE TABLE t2(c INT);
INSERT INTO t2 VALUES(NULL);
CREATE TABLE t3(d INT);
SELECT (b IS TRUE) FROM t1 JOIN t3 ON (b=TRUE) RIGHT JOIN t2 ON TRUE;
SELECT * FROM t1 JOIN t3 ON (b=TRUE) RIGHT JOIN t2 ON TRUE WHERE (b IS TRUE);

.print === right_join scenario 5 full join ===

DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
CREATE TABLE t1 (ID INTEGER);
CREATE TABLE t2 (ID INTEGER);
INSERT INTO t1 VALUES (1);
INSERT INTO t2 VALUES (2);
SELECT * FROM t1 FULL JOIN t2 USING (ID);

.print === right_join scenario 6 full join complex ===

DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS t3;
DROP TABLE IF EXISTS t4;
CREATE TABLE t1(a1 INT);
CREATE TABLE t2(b2 INT);
CREATE TABLE t3(c3 INT, d3 INT UNIQUE);
CREATE TABLE t4(e4 INT, f4 TEXT);
INSERT INTO t3(c3, d3) VALUES (2, 1);
INSERT INTO t4(f4) VALUES ('x');
CREATE INDEX i0 ON t3(c3) WHERE d3 ISNULL;
ANALYZE main;
SELECT * FROM t1 LEFT JOIN t2 ON true JOIN t3 ON (b2 IN (a1)) FULL JOIN t4 ON true;
SELECT 1 FROM t1 LEFT JOIN t2 ON true JOIN t3 ON (b2 IN (a1)) FULL JOIN t4 ON true;

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
