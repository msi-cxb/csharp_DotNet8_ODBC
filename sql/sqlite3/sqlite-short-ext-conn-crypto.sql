.echo on
-- .timer on
.conn sqlite3-crypto

-- =============================================================
-- Test: Crypto Extension - Hash Functions (via connection string)
-- Description: Verifies that md5, sha1, sha256, sha384, and sha512
--              produce the correct hex-encoded digests for 'abc'
--              when crypto.dll is pre-loaded via the connection
--              string. Identical hash assertions to the file segment
--              but confirms the connection-string loading path works.
-- Source: sqlite_extension_crypto in sqliteODBC_tests.vbs (line 2458)
--         SQL3-crypto segment (lines 2494-2511)
-- Connection: sqlite3-crypto (crypto extension pre-loaded)
-- See also: sqlite_extension_crypto_mem.sql  (baseline — no extension)
--           sqlite_extension_crypto_file.sql (load_extension variant)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === md5('abc') — crypto pre-loaded via connection string ===

-- RESULT:hash
-- RESULT:900150983CD24FB0D6963F7D28E17F72
SELECT hex(md5('abc')) AS hash;

.print === sha1('abc') ===

-- RESULT:hash
-- RESULT:A9993E364706816ABA3E25717850C26C9CD0D89D
SELECT hex(sha1('abc')) AS hash;

.print === sha256('abc') ===

-- RESULT:hash
-- RESULT:BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD
SELECT hex(sha256('abc')) AS hash;

.print === sha384('abc') ===

-- RESULT:hash
-- RESULT:CB00753F45A35E8BB5A03D699AC65007272C32AB0EDED1631A8B605A43FF5BED8086072BA1E7CC2358BAECA134C825A7
SELECT hex(sha384('abc')) AS hash;

.print === sha512('abc') ===

-- RESULT:hash
-- RESULT:DDAF35A193617ABACC417349AE20413112E6FA4E89A97EA20A9EEEE64B55D39A2192992A274FC1A836BA3C23A3FEEBBD454D4423643CE80E2A9AC94FA54CA49F
SELECT hex(sha512('abc')) AS hash;

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
