.conn sqlite3

DROP TABLE IF EXISTS t;
CREATE TABLE t (x INTEGER CHECK (x > 0));

-- RESULT-ERROR: CHECK constraint failed: x > 0
INSERT INTO t VALUES (-1);
