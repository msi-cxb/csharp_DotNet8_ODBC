.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: graphExampleTwo
-- Description: Recursive CTE undirected graph - find all nodes connected to node 3
-- Source: graphExampleTwo in sqliteODBC_tests.vbs (line 3392)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === graphExampleTwo undirected graph ===

DROP TABLE IF EXISTS edge;
CREATE TABLE edge(aa INT, bb INT);
CREATE INDEX edge_aa ON edge(aa);
CREATE INDEX edge_bb ON edge(bb);
INSERT INTO edge VALUES(1,2);
INSERT INTO edge VALUES(1,3);
INSERT INTO edge VALUES(1,4);
INSERT INTO edge VALUES(4,5);
INSERT INTO edge VALUES(6,7);
INSERT INTO edge VALUES(7,8);
INSERT INTO edge VALUES(7,9);
INSERT INTO edge VALUES(10,9);
INSERT INTO edge VALUES(11,12);

.print === find all nodes connected to node 3 ===

WITH RECURSIVE nodes(x,y) AS (
   SELECT 3, 'base' AS dir
   UNION
   SELECT aa, bb || '->' || aa AS dir FROM edge JOIN nodes ON bb=x
   UNION
   SELECT bb, aa || '->' || bb AS dir FROM edge JOIN nodes ON aa=x
)
SELECT x, y FROM nodes;

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
