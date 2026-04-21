.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: uint Extension - Binary Collation Baseline (no extension)
-- Description: Verifies standard binary collation ordering of
--              mixed alphanumeric strings WITHOUT the uint extension.
--              The VBScript source also tested that calling
--              load_extension() in this connection mode produces a
--              "Function sequence error" — that behaviour is
--              documented here but not executed, as it requires the
--              install/ DLL folder to be present and the runner to
--              support RESULT-ERROR comparison.
-- Source: sqlite_extension_uint in sqliteODBC_tests.vbs (line 2236)
--         MEM connection segment (lines 2244-2309)
-- Connection: sqlite3 (standard — no extension pre-loaded)
-- See also: sqlite_extension_uint_file.sql (SQL3-uint segment)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === Binary collation sort of mixed alphanumeric strings (no extension needed) ===

SELECT load_extension('%APPDATA%\sqlite\64bit\uint.dll') AS loaded;

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
