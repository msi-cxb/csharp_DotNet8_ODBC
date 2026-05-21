.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: Crypto Extension - Hash Functions (via load_extension)
-- Description: Loads crypto.dll via SELECT load_extension() and
--              verifies that md5, sha1, sha256, sha384, and sha512
--              produce the correct hex-encoded digests for the
--              input string 'abc'. These are the standard test
--              vectors for each algorithm.
--              Requires crypto.dll in the install folder.
-- Source: sqlite_extension_crypto in sqliteODBC_tests.vbs (line 2458)
--         SQL3 segment (lines 2472-2491)
-- Connection: sqlite3 (file-backed, crypto loaded via load_extension)
-- See also: sqlite_extension_crypto_mem.sql  (baseline — no extension)
--           sqlite_extension_crypto_ext.sql  (connection string variant)
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === Load crypto extension ===

-- RESULT:cnt
-- RESULT:0
select count(1) as cnt from (
    SELECT name, narg
    FROM pragma_function_list
    WHERE name IN ('md5', 'sha1', 'sha256', 'sha384', 'sha512')
    ORDER BY name, narg
);

-- RESULT:ext_loaded
-- RESULT:null
SELECT load_extension('%APPDATA%\sqlite\64bit\crypto.dll') AS ext_loaded;

-- RESULT:cnt
-- RESULT:5
select count(1) as cnt from (
    SELECT name, narg
    FROM pragma_function_list
    WHERE name IN ('md5', 'sha1', 'sha256', 'sha384', 'sha512')
    ORDER BY name, narg
);

.print === md5('abc') ===

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
