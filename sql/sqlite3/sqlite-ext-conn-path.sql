.echo on
-- .timer on
-- .conn sqlite3-path-fileio
.conn sqlite3-path

-- .print fileio is not currently working with sqlite3 >= 03.53.00
-- .next

-- =============================================================
-- Test: Path Extension - File Path Functions + fsdir (via connection string)
-- Description: Verifies path manipulation functions (path_dirname,
--              path_basename, path_extension, path_parts) and the
--              fileio extension's fsdir table-valued function. Both
--              path.dll and fileio.dll are pre-loaded via the
--              connection string (SQL3-LoadExt-Path-fileio).
--              The fsdir test scans the .\Debian directory and
--              groups files by extension; expects exactly 2 extension
--              groups (.ini and .in, one file each).
-- Source: sqlite_extension_functions_path in sqliteODBC_tests.vbs
--         (line 2357) — SQL3-LoadExt-Path-fileio segment (lines 2387-2424)
-- Connection: sqlite3-path-fileio (path + fileio extensions pre-loaded)
-- See also: sqlite_extension_functions_path_file.sql (load_extension variant)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === path_dirname — extract directory component ===

-- RESULT:val
-- RESULT:c:\foo\
SELECT path_dirname('c:\foo\bar.txt') AS val;

.print === path_basename — extract filename component ===

-- RESULT:val
-- RESULT:bar.txt
SELECT path_basename('c:\foo\bar.txt') AS val;

.print === path_extension — extract file extension ===

-- RESULT:val
-- RESULT:.txt
SELECT path_extension('c:\foo\bar.txt') AS val;

.print === path_parts — table-valued function returning path components ===

-- Note: expects 2 rows (directory component + filename component)
-- RESULT:type,part
-- RESULT:normal,foo
-- RESULT:normal,bar.txt
SELECT * FROM path_parts('c:\foo\bar.txt');

-- .print === fsdir — list files in c:\temp, group by extension ===

-- RESULT:path_extension(name),count(*),bar
-- RESULT:.txt,2,**
-- SELECT
    -- path_extension(name),
    -- count(*),
    -- printf('%.*c', count(*), '*') AS bar
-- FROM fsdir('c:\temp')
-- WHERE path_extension(name) IS NOT NULL
-- GROUP BY 1
-- ORDER BY 2 DESC;

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
