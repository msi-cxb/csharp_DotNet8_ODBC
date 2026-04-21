.echo on
-- .timer on
.conn sqlite3-totype

-- =============================================================
-- Test: sqlite_extension_functions_totype
-- Description: totype extension - tointeger() and toreal() type conversion functions
-- Source: sqlite_extension_functions_totype in sqliteODBC_tests.vbs (line 1795)
-- Connection: sqlite3-totype
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_functions_totype tointeger ===

-- RESULT:i,r,s
-- RESULT:8,8,8
SELECT tointeger(8) AS i, tointeger(8) AS r, tointeger('8') AS s;

-- RESULT:i,r,s
-- RESULT:null,null,null
SELECT tointeger(8.1) AS i, tointeger(8.1) AS r, tointeger('8.1') AS s;

-- RESULT:i,r,s
-- RESULT:null,null,null
SELECT tointeger(8.9) AS i, tointeger(8.9) AS r, tointeger('8.9') AS s;

.print === sqlite_extension_functions_totype toreal ===

-- RESULT:i,r,s
-- RESULT:8,8,8
SELECT toreal(8) AS i, toreal(8) AS r, toreal('8') AS s;

-- RESULT:i,r,s
-- RESULT:8.1,8.1,8.1
SELECT toreal(8.1) AS i, toreal(8.1) AS r, toreal('8.1') AS s;

-- RESULT:i,r,s
-- RESULT:8.9,8.9,8.9
SELECT toreal(8.9) AS i, toreal(8.9) AS r, toreal('8.9') AS s;

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
