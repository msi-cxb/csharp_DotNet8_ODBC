.echo on
-- .timer on
.conn sqlite3-ieee754

-- =============================================================
-- Test: sqlite_extension_functions_ieee754
-- Description: ieee754 extension - mantissa/exponent, blob conversion functions
-- Source: sqlite_extension_functions_ieee754 in sqliteODBC_tests.vbs (line 2112)
-- Connection: sqlite3-ieee754
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_functions_ieee754 ===

-- RESULT:r
-- RESULT:ieee754(181,-2)
SELECT ieee754(45.25) AS r;

-- RESULT:r
-- RESULT:45.25
SELECT ieee754(181,-2) AS r;

-- RESULT:m,e
-- RESULT:181,-2
SELECT ieee754_mantissa(45.25) AS m, ieee754_exponent(45.25) AS e;

-- RESULT:r
-- RESULT:X'3FF0000000000000'
SELECT ieee754_to_blob(1) AS r;

-- RESULT:r
-- RESULT:1
SELECT ieee754_from_blob(x'3ff0000000000000') AS r;

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
