.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite3_page_size_tests
-- Description: Page size PRAGMA tests - set and change database page size
-- Source: sqlite3_page_size_tests in sqliteODBC_tests.vbs (line 4128)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite3_page_size_tests ===

PRAGMA page_size=8192;
VACUUM;
PRAGMA page_size=4096;
VACUUM;

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
