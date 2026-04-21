.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: Path Extension - File Path Functions (via load_extension)
-- Description: Verifies path manipulation functions provided by
--              path.dll: path_dirname, path_basename, path_extension,
--              and the table-valued function path_parts. The extension
--              is loaded dynamically via SELECT load_extension().
--              Requires path.dll in the install folder.
-- Source: sqlite_extension_functions_path in sqliteODBC_tests.vbs
--         (line 2357) — SQL3 segment (lines 2365-2385)
-- Connection: sqlite3 (file-backed, extension loaded via SQL)
-- See also: sqlite_extension_functions_path_ext.sql (pre-loaded + fsdir)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === Load path extension via SELECT load_extension() ===

-- Note: Requires path.dll in %APPDATA%\sqlite\64bit\ (or x86\) folder.
-- The load_extension call returns NULL on success.
SELECT load_extension('%APPDATA%\sqlite\64bit\path.dll') AS loaded;

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
