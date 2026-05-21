.echo on
-- .timer on
.conn sqlite3-uint

-- =============================================================
-- Test: uint Extension - Natural Number Collation
-- Description: Verifies the uint collation extension, which sorts
--              strings containing embedded unsigned integers in
--              numeric rather than lexicographic order. Tests both
--              standard binary collation (baseline) and uint
--              collation on the same dataset to confirm the
--              difference in ordering behaviour.
--              Example: "node_5" < "node_10" < "node_50" under uint,
--              whereas binary gives "node_10" < "node_5" < "node_50".
-- Source: sqlite_extension_uint in sqliteODBC_tests.vbs (line 2236)
--         SQL3-uint connection segment (lines 2311-2351)
-- Reference: https://sqlite.org/uintcseq.html
-- Connection: sqlite3-uint (uint.dll pre-loaded via connection)
-- See also: sqlite_extension_uint_mem.sql (binary baseline)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === Binary collation sort (baseline — same result with or without uint extension) ===

-- Note: expects 14 rows
-- RESULT:n
-- RESULT:0000123457
-- RESULT:123456
-- RESULT:abc0000000010xyz
-- RESULT:abc0010xyy
-- RESULT:abc10xzz
-- RESULT:abc674xyz
-- RESULT:abc87xyz
-- RESULT:abc9xyz
-- RESULT:node_1
-- RESULT:node_10
-- RESULT:node_100
-- RESULT:node_5
-- RESULT:node_50
-- RESULT:node_500
WITH nodes(n) AS (
    VALUES
        ('node_50'),
        ('abc0010xyy'),
        ('node_100'),
        ('123456'),
        ('abc10xzz'),
        ('node_5'),
        ('abc674xyz'),
        ('0000123457'),
        ('abc0000000010xyz'),
        ('node_500'),
        ('abc87xyz'),
        ('node_10'),
        ('node_1'),
        ('abc9xyz')
)
SELECT n FROM nodes ORDER BY n;

.print === uint collation sort (numeric-aware ordering of embedded integers) ===

-- Note: expects 14 rows
-- Note: pure-numeric strings sort by value first, then alphanumeric groups by
--       their embedded integer (e.g. node_1 < node_5 < node_10 < node_50 < node_100)
-- RESULT:n
-- RESULT:123456
-- RESULT:0000123457
-- RESULT:abc9xyz
-- RESULT:abc0010xyy
-- RESULT:abc0000000010xyz
-- RESULT:abc10xzz
-- RESULT:abc87xyz
-- RESULT:abc674xyz
-- RESULT:node_1
-- RESULT:node_5
-- RESULT:node_10
-- RESULT:node_50
-- RESULT:node_100
-- RESULT:node_500
WITH nodes(n) AS (
    VALUES
        ('node_50'),
        ('abc0010xyy'),
        ('node_100'),
        ('123456'),
        ('abc10xzz'),
        ('node_5'),
        ('abc674xyz'),
        ('0000123457'),
        ('abc0000000010xyz'),
        ('node_500'),
        ('abc87xyz'),
        ('node_10'),
        ('node_1'),
        ('abc9xyz')
)
SELECT n FROM nodes ORDER BY n COLLATE uint;

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
