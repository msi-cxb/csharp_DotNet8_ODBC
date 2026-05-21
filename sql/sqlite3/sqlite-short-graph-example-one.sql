.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: graphExampleOne
-- Description: Recursive CTE tree traversal - depth-first vs breadth-first search
-- Source: graphExampleOne in sqliteODBC_tests.vbs (line 3323)
-- Connection: sqlite3
-- https://sqlite.org/lang_with.html 
-- 3.4. Controlling Depth-First Versus Breadth-First Search Of a Tree Using ORDER BY
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

SELECT sqlite_version() AS vers, sqlite_source_id() AS srcId;

.print === graphExampleOne org tree ===

DROP TABLE IF EXISTS org;
CREATE TABLE org(
    name TEXT PRIMARY KEY,
    boss TEXT REFERENCES org
) WITHOUT ROWID;
INSERT INTO org VALUES('Dave','Bob');
INSERT INTO org VALUES('Fred','Cindy');
INSERT INTO org VALUES('Gail','Cindy');
INSERT INTO org VALUES('Alice',NULL);
INSERT INTO org VALUES('Cindy','Alice');
INSERT INTO org VALUES('Emma','Bob');
INSERT INTO org VALUES('Bob','Alice');

.print === breadth-first with ORDER BY 2 ===

WITH RECURSIVE
  under_alice(name,level) AS (
    VALUES('Alice',0)
    UNION ALL
    SELECT org.name, under_alice.level+1
      FROM org JOIN under_alice ON org.boss=under_alice.name
     ORDER BY 2
  )
SELECT (substr('..........',1,level*3) || name) AS result FROM under_alice;

.print === breadth-first without ORDER BY ===

WITH RECURSIVE
  under_alice(name,level) AS (
    VALUES('Alice',0)
    UNION ALL
    SELECT org.name, under_alice.level+1
      FROM org JOIN under_alice ON org.boss=under_alice.name
  )
SELECT (substr('..........',1,level*3) || name) AS result FROM under_alice;

.print === depth-first with ORDER BY 2 DESC ===

WITH RECURSIVE
  under_alice(name,level) AS (
    VALUES('Alice',0)
    UNION ALL
    SELECT org.name, under_alice.level+1
      FROM org JOIN under_alice ON org.boss=under_alice.name
     ORDER BY 2 DESC
  )
SELECT (substr('..........',1,level*3) || name) AS result FROM under_alice;

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
