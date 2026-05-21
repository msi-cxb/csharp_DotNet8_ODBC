.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite3_recursiveCTE
-- Description: Recursive CTE generating 1 million rows inserted into a table
-- Source: sqlite3_recursiveCTE in sqliteODBC_tests.vbs (line 585)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite3_recursiveCTE ===

DROP TABLE IF EXISTS people;
CREATE TABLE people (id INTEGER, income REAL, tax_rate REAL);

WITH RECURSIVE person(x) AS (
    SELECT 1 UNION ALL SELECT x+1 FROM person WHERE x < 1000000
)
INSERT INTO people (id, income, tax_rate)
SELECT x, 70+mod(x,15)*3, (15.0+(mod(x,5)*0.2)+mod(x,15))/100. FROM person;

-- Note: expects 1 row
-- RESULT:count(1)
-- RESULT:1000000
SELECT count(1) FROM people;

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
