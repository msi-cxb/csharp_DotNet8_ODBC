.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_extension_decimal (MEM segment)
-- Description: decimal extension - high-precision decimal arithmetic via load_extension
-- Source: sqlite_extension_decimal in sqliteODBC_tests.vbs (line 1373)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_decimal MEM load_extension ===

-- Note: load_extension throws error but works
-- Note: expected to fail with: Function sequence error
SELECT load_extension('%APPDATA%\sqlite\64bit\decimal.dll') AS ext_loaded;

SELECT decimal(pi());
SELECT decimal_exp(pi());
SELECT decimal(X'4055480000000000');
SELECT decimal_mul(2, 3);

CREATE TABLE MyTable(X REAL, Y INTEGER, Z TEXT);
INSERT INTO MyTable VALUES (1.1,2,'100'),(2.2,4,'10'),(3.3,6,'1');
SELECT decimal_sum(X) AS dc FROM MyTable;
SELECT decimal_add(X,Y) AS d_a FROM MyTable;
SELECT decimal_sub(X,Y) AS d_s FROM MyTable;
SELECT decimal_mul(X,Y) AS d_m FROM MyTable;
SELECT decimal_pow2(Y) AS d_p FROM MyTable;

.print === decimal_cmp text values ===

-- RESULT:d_c
-- RESULT:1
SELECT decimal_cmp('100.00000000000000001', '100.00000000000000000') AS d_c;
-- RESULT:d_c
-- RESULT:0
SELECT decimal_cmp('100.00000000000000000', '100.00000000000000000') AS d_c;
-- RESULT:d_c
-- RESULT:-1
SELECT decimal_cmp('100.00000000000000000', '100.00000000000000001') AS d_c;

.print === decimal_cmp float values (all equal due to double precision) ===

-- RESULT:d_c
-- RESULT:0
SELECT decimal_cmp(100.00000000000000001, 100.00000000000000000) AS d_c;
-- RESULT:d_c
-- RESULT:0
SELECT decimal_cmp(100.00000000000000000, 100.00000000000000000) AS d_c;
-- RESULT:d_c
-- RESULT:0
SELECT decimal_cmp(100.00000000000000000, 100.00000000000000001) AS d_c;

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
