.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: SQLite DateTime Validation via CHECK Constraint
-- Description: Verifies that a table-level CHECK constraint using
--              strftime/unixepoch correctly rejects invalid dates
--              (e.g. 2025-02-29 in a non-leap year) and accepts
--              valid ones. Also verifies month-boundary calculations
--              across a two-year date range including a leap year.
-- Source: sqlite3_datetime_validation in sqliteODBC_tests.vbs (line 534)
-- Reference: https://sqlite.org/forum/forumpost/6e9d3c43c6
-- Connection: sqlite3 (in-memory equivalent)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === Create date-validation table ===

DROP TABLE IF EXISTS d;
CREATE TABLE d (
    day DATE NOT NULL CHECK (strftime('%F', unixepoch(day), 'unixepoch') = day)
);

.print === Valid date insert: 2025-02-28 (should succeed) ===

INSERT INTO d VALUES ('2025-02-28');

.print === Invalid date insert: 2025-02-29 (2025 is NOT a leap year - CHECK constraint should fire) ===

-- RESULT-ERROR: CHECK constraint failed: strftime('%F', unixepoch(day), 'unixepoch') = day
INSERT INTO d VALUES ('2025-02-29');

.print === Valid date insert: 2024-02-29 (2024 IS a leap year - should succeed) ===

INSERT INTO d VALUES ('2024-02-29');

.print === Clear table and insert two years of valid dates via recursive CTE (2024-01-01 to 2025-12-31) ===

DELETE FROM d;

INSERT INTO d(day)
WITH dates AS (
    SELECT DATE(JULIANDAY('2024-01-01')) AS Date, 1 AS Period
    UNION
    SELECT DATE(JULIANDAY(Date)+1), Period+1
    FROM dates
    WHERE DATE(JULIANDAY(Date)+1) <= DATE(JULIANDAY('2025-12-31'))
)
SELECT date FROM dates ORDER BY Date;

.print === First and last day of each month (2024 leap year + 2025 non-leap year) ===

-- Note: expects 24 rows (12 months x 2 years)
-- Note: 2024-02 last day is 2024-02-29 (leap); 2025-02 last day is 2025-02-28 (non-leap)
-- RESULT:firstOfMonth,lastOfMonth
-- RESULT:20240101120000,2024-01-31
-- RESULT:20240201120000,2024-02-29
-- RESULT:20240301120000,2024-03-31
-- RESULT:20240401120000,2024-04-30
-- RESULT:20240501120000,2024-05-31
-- RESULT:20240601120000,2024-06-30
-- RESULT:20240701120000,2024-07-31
-- RESULT:20240801120000,2024-08-31
-- RESULT:20240901120000,2024-09-30
-- RESULT:20241001120000,2024-10-31
-- RESULT:20241101120000,2024-11-30
-- RESULT:20241201120000,2024-12-31
-- RESULT:20250101120000,2025-01-31
-- RESULT:20250201120000,2025-02-28
-- RESULT:20250301120000,2025-03-31
-- RESULT:20250401120000,2025-04-30
-- RESULT:20250501120000,2025-05-31
-- RESULT:20250601120000,2025-06-30
-- RESULT:20250701120000,2025-07-31
-- RESULT:20250801120000,2025-08-31
-- RESULT:20250901120000,2025-09-30
-- RESULT:20251001120000,2025-10-31
-- RESULT:20251101120000,2025-11-30
-- RESULT:20251201120000,2025-12-31
SELECT
    day AS firstOfMonth,
    date(day, 'start of month', '+1 month', '-1 day') AS lastOfMonth
FROM d
WHERE strftime('%d', day) = '01';

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
