.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: recursiveCTE (MEM segment)
-- Description: Simple recursive CTE examples - counter, sum of naturals
-- Source: recursiveCTE in sqliteODBC_tests.vbs (line 3517)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === recursiveCTE simple counter ===

WITH RECURSIVE counter(x) AS (
    SELECT 0
    UNION
    SELECT x + 1 FROM counter
)
SELECT * FROM counter LIMIT 5;

.print === recursiveCTE with column alias ===

WITH RECURSIVE counter AS (
    SELECT 0 AS x
    UNION
    SELECT x + 1 FROM counter
)
SELECT * FROM counter LIMIT 5;

.print === recursiveCTE two arguments ===

WITH RECURSIVE counter(x,y) AS (
    SELECT 0 AS x, 1 AS y
    UNION
    SELECT x + 1, y + 2 FROM counter
)
SELECT * FROM counter LIMIT 5;

.print === recursiveCTE sum of naturals 1 to 100 ===

-- Sum of all natural numbers from 1 to 100 is 5050
WITH RECURSIVE
  cnt(x) AS (
     SELECT 1
     UNION ALL
     SELECT x+1
     FROM cnt
     LIMIT 100
) SELECT sum(x) AS sumX FROM cnt;

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
