.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: generate_series
-- Description: Generate series using recursive CTE pattern
-- Source: generate_series in sqliteODBC_tests.vbs (line 3032)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === generate_series ===

WITH RECURSIVE
  generate_series(value) AS (
    SELECT 5
    UNION ALL
    SELECT value+5 FROM generate_series
      WHERE value+5<=100
  ) SELECT value FROM generate_series;

SELECT * FROM (
    WITH RECURSIVE
      generate_series(value) AS (
        SELECT 5
        UNION ALL
        SELECT value+5 FROM generate_series
          WHERE value+5<=100
      ) SELECT value FROM generate_series
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
