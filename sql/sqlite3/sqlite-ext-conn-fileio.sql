.echo on
-- .timer on
.conn sqlite3-fileio

-- .print as of 03.53.00 fileio does not work through ODBC
-- .next

-- =============================================================
-- Test: sqlite_extension_fileio (SQL3-fileio segment)
-- Description: fileio extension - fsdir, readfile functions via connection string
-- Source: sqlite_extension_fileio in sqliteODBC_tests.vbs (line 1297)
-- Connection: sqlite3-fileio
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_fileio SQL3-fileio connection ===

DROP TABLE IF EXISTS fileInfo_C_Temp;

SELECT name FROM fsdir('c:\temp');

CREATE TABLE fileInfo_C_Temp AS SELECT name FROM fsdir('c:\temp');

PRAGMA table_info('fileInfo_C_Temp');

SELECT count(1) AS numRecords FROM fileInfo_C_Temp;

.print === fsdir with dir and path ===

SELECT name,
    printf('%08X',mode) AS m,
    ( printf('%04X',(mode & 0xF000)) == '8000' ) AS isFile,
    ( printf('%04X',(mode & 0xF000)) == '4000' ) AS isDir,
    ( printf('%04X',(mode & 0x0100)) == '0100' ) AS isRead,
    ( printf('%04X',(mode & 0x0080)) == '0080' ) AS isWrite,
    ( printf('%04X',(mode & 0x0040)) == '0040' ) AS isExe,
    '' AS theEnd
FROM fsdir('.\data\test.csv');

.print === fsdir with explicit path ===

SELECT name,
    printf('%08X',mode) AS m,
    ( printf('%04X',(mode & 0xF000)) == '8000' ) AS isFile,
    ( printf('%04X',(mode & 0xF000)) == '4000' ) AS isDir,
    ( printf('%04X',(mode & 0x0100)) == '0100' ) AS isRead,
    ( printf('%04X',(mode & 0x0080)) == '0080' ) AS isWrite,
    ( printf('%04X',(mode & 0x0040)) == '0040' ) AS isExe,
    '' AS theEnd
FROM fsdir('c:\temp');

.print === readfile text ===

SELECT cast(readfile('.\data\test.csv') AS text) AS fileContent;

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
