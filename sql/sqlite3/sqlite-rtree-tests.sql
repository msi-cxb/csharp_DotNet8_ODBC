.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite3_rtree_tests
-- Description: R-Tree virtual table tests - spatial indexing 
-- built into odbc driver
-- Source: sqlite3_rtree_tests in sqliteODBC_tests.vbs (line 4141)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite3_rtree_tests ===

PRAGMA compile_options;

DROP TABLE IF EXISTS demo_index;

CREATE VIRTUAL TABLE demo_index USING rtree(
    id, minX, maxX, minY, maxY
);

INSERT INTO demo_index VALUES
  (28215, -80.781227, -80.604706, 35.208813, 35.297367),
  (28216, -80.957283, -80.840599, 35.235920, 35.367825),
  (28217, -80.960869, -80.869431, 35.133682, 35.208233),
  (28226, -80.878983, -80.778275, 35.060287, 35.154446),
  (28227, -80.745544, -80.555382, 35.130215, 35.236916),
  (28244, -80.844208, -80.841988, 35.223728, 35.225471),
  (28262, -80.809074, -80.682938, 35.276207, 35.377747),
  (28269, -80.851471, -80.735718, 35.272560, 35.407925),
  (28270, -80.794983, -80.728966, 35.059872, 35.161823),
  (28273, -80.994766, -80.875259, 35.074734, 35.172836),
  (28277, -80.876793, -80.767586, 35.001709, 35.101063),
  (28278, -81.058029, -80.956375, 35.044701, 35.223812),
  (28280, -80.844208, -80.841972, 35.225468, 35.227203),
  (28282, -80.846382, -80.844193, 35.223972, 35.225655);

-- RESULT:id,minX,maxX,minY,maxY
-- RESULT:28215,-80.7812271118164,-80.6047058105469,35.208812713623,35.2973670959473
SELECT * FROM demo_index WHERE id=28215;

-- RESULT:min(minx),max(minX)
-- RESULT:-81.0580291748047,-80.7455444335938
SELECT min(minx), max(minX) from demo_index;

-- RESULT:min(maxX),max(maxX)
-- RESULT:-80.9563674926758,-80.5553817749023
SELECT min(maxX), max(maxX) from demo_index;

-- RESULT:min(minY),max(minY)
-- RESULT:35.001708984375,35.2762069702148
SELECT min(minY), max(minY) from demo_index;

-- RESULT:min(maxY),max(maxY)
-- RESULT:35.1010665893555,35.4079284667969
SELECT min(maxY), max(maxY) from demo_index;

-- RESULT:id
-- RESULT:28216
-- RESULT:28217
-- RESULT:28273
SELECT id FROM demo_index WHERE minX>=-81.0 AND minX<=-80.90;


DROP TABLE IF EXISTS demo_index2;

CREATE VIRTUAL TABLE demo_index2 USING rtree(
    id,
    minX, maxX,
    minY, maxY,
    +objname TEXT,
    +objtype TEXT,
    +boundary BLOB
);

INSERT INTO demo_index2 VALUES
  (28215, -80.781227, -80.604706, 35.208813, 35.297367,'x','y','z'),
  (28216, -80.957283, -80.840599, 35.235920, 35.367825,'x','y','z'),
  (28217, -80.960869, -80.869431, 35.133682, 35.208233,'x','y','z'),
  (28226, -80.878983, -80.778275, 35.060287, 35.154446,'x','y','z'),
  (28227, -80.745544, -80.555382, 35.130215, 35.236916,'x','y','z'),
  (28244, -80.844208, -80.841988, 35.223728, 35.225471,'x','y','z'),
  (28262, -80.809074, -80.682938, 35.276207, 35.377747,'x','y','z'),
  (28269, -80.851471, -80.735718, 35.272560, 35.407925,'x','y','z'),
  (28270, -80.794983, -80.728966, 35.059872, 35.161823,'x','y','z'),
  (28273, -80.994766, -80.875259, 35.074734, 35.172836,'x','y','z'),
  (28277, -80.876793, -80.767586, 35.001709, 35.101063,'x','y','z'),
  (28278, -81.058029, -80.956375, 35.044701, 35.223812,'x','y','z'),
  (28280, -80.844208, -80.841972, 35.225468, 35.227203,'x','y','z'),
  (28282, -80.846382, -80.844193, 35.223972, 35.225655,'x','y','z');

--  RESULT:ok
SELECT rtreecheck('demo_index');

--  RESULT:ok
SELECT rtreecheck('demo_index2');

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
