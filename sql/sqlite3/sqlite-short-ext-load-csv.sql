.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: CSV Virtual Table Extension (via load_extension)
-- Description: Verifies the csv virtual table module by loading
--              csv.dll via SELECT load_extension() and creating a
--              virtual table from a .\data\test.csv file. The test confirms
--              that the table has the expected row and column count
--              (4 rows × 5 columns). Requires csv.dll in the install
--              folder and .\data\test.csv in the working/data directory.
-- Source: sqlite_extension_functions_csv in sqliteODBC_tests.vbs
--         (line 2430) — SQL3 segment (lines 2436-2443)
-- Connection: sqlite3 (file-backed, extension loaded via SQL)
-- See also: sqlite_extension_functions_csv_ext.sql (connection string variant)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === Load csv extension and create virtual table from .\data\test.csv ===

-- Note: Requires csv.dll in %APPDATA%\sqlite\64bit\ and .\data\test.csv in the data directory.
SELECT load_extension('%APPDATA%\sqlite\64bit\csv.dll') AS loaded;

CREATE VIRTUAL TABLE temp.t1 USING csv(filename='.\data\test.csv', header=true);

.print === Query all rows from CSV virtual table (expects 4 rows x 5 columns) ===

-- Note: expects 4 rows
-- RESULT:col_1,col_2,col_3,col_4,col_5
-- RESULT:1,2,3.3,4,5
-- RESULT:2,2,6.6,8,25
-- RESULT:3,6,9.9,12,125
-- RESULT:4,8,12.12,16,625
SELECT * FROM t1;

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
