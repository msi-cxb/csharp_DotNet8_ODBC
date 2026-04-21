.echo on
-- .timer on
.conn sqlite3-bfsvtab

-- =============================================================
-- Test: sqlite_extension_bfsvtab (SQL3-bfsvtab segment)
-- Description: bfsvtab extension - BFS graph traversal via connection string
-- Source: sqlite_extension_bfsvtab in sqliteODBC_tests.vbs (line 1521)
-- Connection: sqlite3-bfsvtab
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_bfsvtab SQL3-bfsvtab connection ===

DROP TABLE IF EXISTS edges;
CREATE TABLE edges(fromNode INTEGER, toNode INTEGER);
INSERT INTO edges(fromNode, toNode) VALUES (1,2),(1,3),(2,4),(3,4);

.print === shortest path node 1 to node 4 ===

-- Note: expects 1 row
SELECT id, distance
FROM bfsvtab
WHERE tablename  = 'edges'
  AND fromcolumn = 'fromNode'
  AND tocolumn   = 'toNode'
  AND root       = 1
  AND id         = 4;

.print === min distance from node 1 to all nodes ===

-- Note: expects 4 rows
SELECT id, distance
FROM bfsvtab
WHERE tablename  = 'edges'
  AND fromcolumn = 'fromNode'
  AND tocolumn   = 'toNode'
  AND root       = 1;

.print === spanning tree rooted at node 1 ===

-- Note: expects 3 rows
SELECT id, distance
FROM bfsvtab
WHERE tablename  = 'edges'
  AND fromcolumn = 'fromNode'
  AND tocolumn   = 'toNode'
  AND root       = 1
  AND parent     IS NOT NULL;

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
