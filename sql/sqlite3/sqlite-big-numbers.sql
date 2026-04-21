.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_big_numbers
-- Description: 64-bit integer behavior in SQLite with ODBC - 2^63 edge cases
-- Source: sqlite_big_numbers in sqliteODBC_tests.vbs (line 3581)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_big_numbers ===

DROP TABLE IF EXISTS big_numbers;
CREATE TABLE big_numbers (i INTEGER, r REAL, t TEXT, b BLOB);

-- 2^63 - 1
INSERT INTO big_numbers VALUES (9223372036854775807, 9223372036854775807, 9223372036854775807, 9223372036854775807);
-- 2^63
INSERT INTO big_numbers VALUES (9223372036854775808, 9223372036854775808, 9223372036854775808, 9223372036854775808);

.print === select all big_numbers ===

SELECT * FROM big_numbers;

.print === typeof columns ===

-- Expected sqlite3 output:
-- integer real text integer
-- real real text real
SELECT typeof(i), typeof(r), typeof(t), typeof(b) FROM big_numbers;

.print === arithmetic with big numbers ===

SELECT i+1, r+1, t+1, b+1 FROM big_numbers;
SELECT i, i+1 FROM big_numbers;

.print === using cast to force real type ===

SELECT CAST(i AS REAL) AS i, CAST((i+1) AS REAL) AS 'i+1' FROM big_numbers;

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
