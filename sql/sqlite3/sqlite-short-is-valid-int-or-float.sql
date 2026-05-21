.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: isValidIntOrFloat
-- Description: Check if a text value is a valid integer or float
-- Source: isValidIntOrFloat in sqliteODBC_tests.vbs (line 3434)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === isValidIntOrFloat float version ===

-- Expected: Null row, 1, 1, 0
SELECT
    value,
    CAST(CAST(value AS REAL) AS TEXT) IN (value, value || '.0') AS is_valid_float
FROM (
    SELECT '1' AS value
    UNION SELECT '1.1' AS value
    UNION SELECT 'dog' AS value
    UNION SELECT NULL AS value
);

.print === isValidIntOrFloat integer version ===

-- Expected: Null row, 1, 0, 0
SELECT
    value,
    CAST(CAST(value AS INTEGER) AS TEXT) = value AS is_valid_int
FROM (
    SELECT '1' AS value
    UNION SELECT '1.1' AS value
    UNION SELECT 'dog' AS value
    UNION SELECT NULL AS value
);

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
