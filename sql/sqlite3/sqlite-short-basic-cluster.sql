.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_basic_cluster
-- Description: Clustering dates together using window functions - groups dates within 5 days
-- Source: sqlite_basic_cluster in sqliteODBC_tests.vbs (line 934)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_basic_cluster ===

CREATE TEMP TABLE some_data(action DATE);

INSERT INTO temp.some_data VALUES ('2000-01-01');
INSERT INTO temp.some_data VALUES ('2000-01-01');
INSERT INTO temp.some_data VALUES ('2000-01-02');
INSERT INTO temp.some_data VALUES ('2000-01-04');
INSERT INTO temp.some_data VALUES ('2000-01-25');
INSERT INTO temp.some_data VALUES ('2000-01-31');
INSERT INTO temp.some_data VALUES ('2000-02-01');
INSERT INTO temp.some_data VALUES ('2000-02-01');
INSERT INTO temp.some_data VALUES ('2000-02-01');
INSERT INTO temp.some_data VALUES ('2000-02-07');
INSERT INTO temp.some_data VALUES ('2000-03-01');
INSERT INTO temp.some_data VALUES ('2000-03-02');
INSERT INTO temp.some_data VALUES ('2000-03-02');
INSERT INTO temp.some_data VALUES ('2000-03-02');

-- Note: expects 5 rows
-- RESULT:Start,End
-- RESULT:2000-01-01,2000-01-04
-- RESULT:2000-01-25,2000-01-25
-- RESULT:2000-01-31,2000-02-01
-- RESULT:2000-02-07,2000-02-07
-- RESULT:2000-03-01,2000-03-02
WITH
    edge_detect AS (
        SELECT action,
            julianday(action)-julianday(lag(action) OVER ()) <= 5 AS ingrp
        FROM some_data
        ORDER BY action
    ),
    build_grouping AS (
        SELECT action, COUNT(*) FILTER (WHERE ingrp IS NOT 1)
            OVER (ROWS UNBOUNDED PRECEDING) AS g
        FROM edge_detect
    )
SELECT MIN(action) AS Start, MAX(action) AS End
FROM build_grouping
GROUP BY g;

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
