.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite3_BuiltIn_Tests (includes sqlite_math_functions)
-- Description: Built-in math functions test - trig, log, floor, ceil, etc.
-- Source: sqlite3_BuiltIn_Tests in sqliteODBC_tests.vbs (line 4299)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite3_BuiltIn_Tests math functions ===

SELECT acos(30*3.14159/180) AS x;
SELECT acosh(30*3.14159/180) AS x;
SELECT asin(30*3.14159/180) AS x;
SELECT asinh(30*3.14159/180) AS x;
SELECT atan(30*3.14159/180) AS x;
SELECT atanh(30*3.14159/180) AS x;
SELECT atan2(4,5) AS x;

-- Note: expected to fail with: no such function: atn2
-- RESULT-ERROR: no such function: atn2 (1) (source: sqlite3odbc.dll)
SELECT atn2(4,5) AS x;

SELECT ceil(1.1) AS x;
SELECT ceiling(1.1) AS x;
SELECT cos(30*3.14159/180) AS x;
SELECT cosh(30*3.14159/180) AS x;

-- Note: expected to fail with: no such function: cot
-- RESULT-ERROR: no such function: cot (1) (source: sqlite3odbc.dll)
SELECT cot(30*3.14159/180) AS x;

-- Note: expected to fail with: no such function: coth
-- RESULT-ERROR: no such function: coth (1) (source: sqlite3odbc.dll)
SELECT coth(30*3.14159/180) AS x;

SELECT degrees(30*3.14159/180) AS x;
SELECT exp(2) AS x;
SELECT floor(1.1) AS w, floor(1.9) AS x, floor(-1.1) AS y, floor(-1.9) AS z;

-- RESULT:x
-- RESULT:2.30258509299405
SELECT ln(10) AS x;

-- RESULT:x,y,z
-- RESULT:3.32192809488736,1,0.830482023721841
SELECT log(2,10) AS x, log(10,10) AS y, log(16,10) AS z;

-- RESULT:x
-- RESULT:1
SELECT log(10) AS x;

-- RESULT:x
-- RESULT:1
SELECT log10(10) AS x;

-- RESULT:x
-- RESULT:3.32192809488736
SELECT log2(10) AS x;

SELECT mod(10,10) AS x, mod(10,11) AS y;
SELECT pi() AS x;
SELECT pow(2,2) AS x;
SELECT power(2,2) AS x;
SELECT radians(180) AS x;
SELECT sign(-10) AS x, sign(10) AS y;
SELECT sin(30*3.14159/180) AS x;
SELECT sinh(30*3.14159/180) AS x;
SELECT sqrt(4) AS x;

-- Note: expected to fail with: no such function: square
-- RESULT-ERROR: no such function: square (1) (source: sqlite3odbc.dll)
SELECT square(4) AS x;

SELECT tan(30*3.14159/180) AS x;
SELECT tanh(30*3.14159/180) AS x;

-- RESULT:x,y
-- RESULT:1,1
SELECT trunc(1.123) AS x, trunc(1.9) AS y;

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
