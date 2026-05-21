.echo on
-- .timer on
.conn sqlite3-series

-- =============================================================
-- Test: Insert Performance Benchmark - Pragma Combinations
-- Description: Documents the pragma configuration space tested by
--              the insertTests VBScript function, which benchmarks
--              SQLite insert throughput across all combinations of:
--                mmap_size   : 0 | 1073741824 | 2147483648
--                cache_size  : -2000 | -4000
--                journal_mode: WAL | MEMORY | OFF | DELETE | TRUNCATE | PERSIST
--                page_size   : 4096 | 16384
--                synchronous : OFF | NORMAL | FULL | EXTRA
--                temp_store  : MEMORY | FILE
--                locking_mode: EXCLUSIVE | NORMAL
--              Each combination inserts 100 rows × 25 columns using
--              ADODB AddNew (row-by-row via ODBC), which is not
--              directly replicable as plain SQL. This file instead
--              verifies the pragma settings are accepted and
--              demonstrates a representative insert pattern using
--              generate_series for a single pragma configuration.
-- Source: insertTests in sqliteODBC_tests.vbs (line 4717)
--         test() helper function (line 4807)
-- Connection: sqlite3 (file-backed)
-- Note: The original benchmark uses ADODB AddNew and cannot be
--       reproduced as a SQL file. This file tests pragma acceptance
--       and a single representative insert workload.
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === Verify all benchmark pragma settings are accepted ===

-- mmap_size: 0 (off), 1 GB, 2 GB
PRAGMA mmap_size = 0;
PRAGMA mmap_size = 1073741824;
PRAGMA mmap_size = 2147483648;

-- cache_size: -2000 (default ~2 MB), -4000 (~4 MB)
PRAGMA cache_size = -2000;
PRAGMA cache_size = -4000;

-- journal_mode: all supported modes
PRAGMA journal_mode = WAL;
PRAGMA journal_mode = MEMORY;
PRAGMA journal_mode = OFF;
PRAGMA journal_mode = DELETE;
PRAGMA journal_mode = TRUNCATE;
PRAGMA journal_mode = PERSIST;
PRAGMA journal_mode = WAL;

-- page_size: 4096 (default) and 16384 — only effective before first write
-- RESULT:page_size
-- RESULT:4096
PRAGMA page_size;

-- synchronous: OFF | NORMAL | FULL | EXTRA
PRAGMA synchronous = OFF;
PRAGMA synchronous = NORMAL;
PRAGMA synchronous = FULL;
PRAGMA synchronous = EXTRA;
PRAGMA synchronous = NORMAL;

-- temp_store: MEMORY | FILE
PRAGMA temp_store = MEMORY;
PRAGMA temp_store = FILE;
PRAGMA temp_store = MEMORY;

-- locking_mode: EXCLUSIVE | NORMAL
PRAGMA locking_mode = EXCLUSIVE;
PRAGMA locking_mode = NORMAL;

.print === Representative insert benchmark: 100 rows x 25 INTEGER columns ===

DROP TABLE IF EXISTS bench;
CREATE TABLE bench (
    c01 INTEGER, c02 INTEGER, c03 INTEGER, c04 INTEGER, c05 INTEGER,
    c06 INTEGER, c07 INTEGER, c08 INTEGER, c09 INTEGER, c10 INTEGER,
    c11 INTEGER, c12 INTEGER, c13 INTEGER, c14 INTEGER, c15 INTEGER,
    c16 INTEGER, c17 INTEGER, c18 INTEGER, c19 INTEGER, c20 INTEGER,
    c21 INTEGER, c22 INTEGER, c23 INTEGER, c24 INTEGER, c25 INTEGER
);

PRAGMA journal_mode = WAL;
PRAGMA synchronous  = NORMAL;
PRAGMA cache_size   = -4000;
PRAGMA mmap_size    = 1073741824;
PRAGMA locking_mode = EXCLUSIVE;
PRAGMA temp_store   = MEMORY;

INSERT INTO bench
SELECT
    value, value+1, value+2, value+3, value+4,
    value+5, value+6, value+7, value+8, value+9,
    value+10, value+11, value+12, value+13, value+14,
    value+15, value+16, value+17, value+18, value+19,
    value+20, value+21, value+22, value+23, value+24
FROM generate_series(1, 100);

-- Note: expects 1 row
-- RESULT:row_count
-- RESULT:100
SELECT count(*) AS row_count FROM bench;

PRAGMA locking_mode = NORMAL;

DROP TABLE IF EXISTS bench;

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
