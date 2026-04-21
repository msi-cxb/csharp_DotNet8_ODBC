.echo on
-- .timer on
.conn sqlite3-"extension-functions"

-- =============================================================
-- Test: Extension-Functions - String and Aggregate Functions
-- Description: Verifies the extension-functions extension, which
--              adds string manipulation functions (charindex, leftstr,
--              padc, padl, padr, proper, replicate, reverse, rightstr,
--              strfilter) and statistical aggregates (lower_quartile,
--              median, mode, stdev, upper_quartile, variance).
--              The extension is pre-loaded via the connection string.
--              CSV aggregate tests require csv.dll loaded separately
--              and a .\data\test.csv data file (4 rows × 5 columns).
-- Source: sqlite_extension_functions_tests in sqliteODBC_tests.vbs
--         (line 2150) — SQL3-LoadExt-ExtFun segment (lines 2160-2163)
--         sqlite3_extension_functions helper (lines 2168-2233)
-- Reference: https://www.sqlite.org/contrib/download/extension-functions.c
-- Connection: sqlite3-extension-functions (extension pre-loaded)
-- See also: sqlite_extension_functions_tests_mem.sql (no-extension baseline)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === charindex(S1,S2) — find first occurrence of S1 in S2 ===

-- RESULT:x
-- RESULT:7
SELECT charindex('world', 'hello world!') AS x;

.print === charindex(S1,S2,N) — find occurrence starting from position N ===

-- RESULT:x
-- RESULT:20
SELECT charindex('world', 'hello world! hello world!', 10) AS x;

.print === leftstr(S,N) — return leftmost N characters ===

-- RESULT:x
-- RESULT:hello
SELECT leftstr('hello world!', 5) AS x;

.print === padc(S,N) — centre-pad string to width N ===

.echo on
-- RESULT:'|',x,'|'
-- RESULT:|,                        10                        ,|
SELECT '|', padc('10', 50) AS x, '|';

.print === padl(S,N) — left-pad string to width N ===

-- RESULT:'|',x,'|'
-- RESULT:|,                                                10,|
SELECT '|', padl('10', 50) AS x, '|';

.print === padr(S,N) — right-pad string to width N ===

-- RESULT:'|',x,'|'
-- RESULT:|,10                                                ,|
SELECT '|', padr('10', 50) AS x, '|';

.print === proper(S) — title-case conversion ===

-- RESULT:x
-- RESULT:Hello World!
SELECT proper('hElLo WoRlD!') AS x;

.print === replicate(S,N) — repeat string N times ===

-- RESULT:x
-- RESULT:hElLo WoRlD fIvE tImEs!hElLo WoRlD fIvE tImEs!hElLo WoRlD fIvE tImEs!hElLo WoRlD fIvE tImEs!hElLo WoRlD fIvE tImEs!
SELECT replicate('hElLo WoRlD fIvE tImEs!', 5) AS x;

.print === reverse(S) — reverse string ===

-- RESULT:x
-- RESULT:!DlRoW oLlEh
SELECT reverse('hElLo WoRlD!') AS x;

.print === rightstr(S,N) — return rightmost N characters ===

-- RESULT:x
-- RESULT:world!
SELECT rightstr('hello world!', 6) AS x;

.print === strfilter(S1,S2) — keep only characters from S2 that appear in S1 ===

-- RESULT:x
-- RESULT:oo!
SELECT strfilter('hello world!', 'o!') AS x;

.print === CSV aggregate functions — requires csv.dll and .\data\test.csv data file ===
-- Note: The following tests require csv.dll to be loaded and a .\data\test.csv file
--       with header=true, 4 data rows, and at least 2 numeric columns (col_1=1,2,3,4).
--       Uncomment and run when DLLs and data files are available.

-- SELECT load_extension('.\extensions\sqlite3\x64\csv.dll') AS loaded;
-- CREATE VIRTUAL TABLE temp.t1 USING csv(filename='.\data\test.csv', header=true);

-- lower_quartile(X) aggregate: expects 1.5
-- RESULT:x
-- RESULT:1.5
-- SELECT lower_quartile(col_1) AS x FROM t1;

-- median(X) aggregate: expects 2.5
-- RESULT:x
-- RESULT:2.5
-- SELECT median(col_1) AS x FROM t1;

-- mode(X) aggregate: expects 2
-- RESULT:x
-- RESULT:2
-- SELECT mode(col_2) AS x FROM t1;

-- stdev(X) aggregate: expects 1.29099444873581
-- RESULT:x
-- RESULT:1.29099444873581
-- SELECT stdev(col_1) AS x FROM t1;

-- upper_quartile(X) aggregate: expects 3.5
-- RESULT:x
-- RESULT:3.5
-- SELECT upper_quartile(col_1) AS x FROM t1;

-- variance(X) aggregate: expects 1.66666666666667
-- RESULT:x
-- RESULT:1.66666666666667
-- SELECT variance(col_1) AS x FROM t1;

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
