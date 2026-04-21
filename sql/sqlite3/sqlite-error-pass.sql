.conn sqlite3

DROP TABLE IF EXISTS t;
CREATE TABLE t (x INTEGER CHECK (x > 0));

-- RESULT-ERROR: CHECK constraint failed
INSERT INTO t VALUES (-1);

-- Verify the table is still intact after the expected error
-- RESULT:count
-- RESULT:0
SELECT COUNT(*) AS count FROM t;
