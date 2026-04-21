.echo on
-- .timer on
.conn sqlite3-csv

-- =============================================================
-- Test: CSV Virtual Table Extension (via connection string)
-- Description: Verifies the csv virtual table module when csv.dll
--              is pre-loaded via the connection string. Creates a
--              virtual table from .\data\test.csv and confirms 4 rows × 5
--              columns. Requires .\data\test.csv in the working/data directory.
-- Source: sqlite_extension_functions_csv in sqliteODBC_tests.vbs
--         (line 2430) — SQL3-LoadExt-Csv segment (lines 2446-2452)
-- Connection: sqlite3-csv (csv extension pre-loaded via connection string)
-- See also: sqlite_extension_functions_csv_file.sql (load_extension variant)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === Create CSV virtual table (csv extension pre-loaded via connection string) ===

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
