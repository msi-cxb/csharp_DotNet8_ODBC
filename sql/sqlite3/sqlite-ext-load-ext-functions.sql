.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: Extension-Functions - Load Attempt in Standard Connection
-- Description: Documents the behaviour when attempting to load
--              extension-functions.dll via SELECT load_extension()
--              in a standard (non-extension) connection. Extension
--              loading is disabled in this mode; calling any of the
--              string/math functions added by the extension (e.g.
--              charindex, leftstr, proper, replicate, reverse) would
--              fail because the DLL was never loaded.
--              The actual function tests run in
--              sqlite_extension_functions_tests_ext.sql where the
--              extension is pre-loaded via the connection string.
-- Source: sqlite_extension_functions_tests in sqliteODBC_tests.vbs
--         (line 2150) — MEM segment (lines 2154-2158)
-- Connection: sqlite3 (standard — no extension pre-loaded)
-- See also: sqlite-ext-conn-ext-functions.sql
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === Check that extension-functions are NOT present in function list ===

-- Without the extension loaded, none of charindex/leftstr/proper/etc. appear.
-- Note: expects 0 rows
-- RESULT:cnt
-- RESULT:0
SELECT COUNT(1) AS cnt from (
    SELECT name, narg
FROM pragma_function_list
WHERE name IN ('charindex','leftstr','padc','padl','padr','proper',
               'replicate','reverse','rightstr','strfilter',
               'lower_quartile','median','stdev','upper_quartile','variance')
ORDER BY name, narg
);

.print === Verify that calling an extension function without the extension raises an error ===

-- RESULT-ERROR: no such function: charindex
SELECT charindex('world', 'hello world!') AS x;

-- RESULT:loaded
-- RESULT:null
SELECT load_extension('%APPDATA%\sqlite\64bit\extension-functions.dll') AS loaded;

-- RESULT:name,narg
-- RESULT:charindex,2
-- RESULT:charindex,3
-- RESULT:leftstr,2
-- RESULT:lower_quartile,1
-- RESULT:median,1
-- RESULT:padc,2
-- RESULT:padl,2
-- RESULT:padr,2
-- RESULT:proper,1
-- RESULT:replicate,2
-- RESULT:reverse,1
-- RESULT:rightstr,2
-- RESULT:stdev,1
-- RESULT:strfilter,2
-- RESULT:upper_quartile,1
-- RESULT:variance,1
SELECT name, narg
FROM pragma_function_list
WHERE name IN ('charindex','leftstr','padc','padl','padr','proper',
               'replicate','reverse','rightstr','strfilter',
               'lower_quartile','median','stdev','upper_quartile','variance')
ORDER BY name, narg;


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
