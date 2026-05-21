.echo on
-- .timer on
.conn sqlite3-shathree

-- =============================================================
-- Test: sqlite_extension_functions_sha (SQL3-sha segment)
-- Description: shathree extension - sha3 hash functions via connection string + million row hash
-- Source: sqlite_extension_functions_sha in sqliteODBC_tests.vbs (line 1838)
-- Connection: sqlite3-sha
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_extension_functions_sha SQL3-sha connection ===

-- RESULT:r
-- RESULT:1
SELECT sha3(1) = sha3('1') as r;
-- RESULT:r
-- RESULT:1
SELECT sha3('hello') = sha3(x'68656c6c6f') as r;
-- RESULT:r
-- RESULT:1
WITH a(x) AS (VALUES('xyzzy')) SELECT sha3_agg(x) = sha3('T5:xyzzy') as r FROM a ;
-- RESULT:r
-- RESULT:1
WITH a(x) AS (VALUES(x'010203')) SELECT sha3_agg(x) = sha3(x'42333a010203') as r FROM a;
-- RESULT:r
-- RESULT:1
WITH a(x) AS (VALUES(0x123456)) SELECT sha3_agg(x) = sha3(x'490000000000123456') as r FROM a;
-- RESULT:r
-- RESULT:1
WITH a(x) AS (VALUES(100.015625)) SELECT sha3_agg(x) = sha3(x'464059010000000000') as r FROM a;
-- RESULT:r
-- RESULT:1
WITH a(x) AS (VALUES(NULL)) SELECT sha3_agg(x) = sha3('N') as r FROM a;

.print === sha3 on million-row table ===

DROP TABLE IF EXISTS people;
CREATE TABLE people (id INTEGER, income REAL, tax_rate REAL);

WITH RECURSIVE person(x) AS (
    SELECT 1 UNION ALL SELECT x+1 FROM person WHERE x < 1000000
)
INSERT INTO people (id, income, tax_rate)
SELECT x, 70+mod(x,15)*3, (15.0+(mod(x,5)*0.2)+mod(x,15))/100. FROM person;

-- Note: expects 1 row
-- RESULT:cnt
-- RESULT:1000000
SELECT count(1) as cnt FROM people;

-- RESULT:r
-- RESULT:6274E2DC85CDEB0A4E355B9FF79CFBCB95995779A4E7DDB90E3D312A7CF46278
SELECT hex(sha3_agg(id)) as r FROM people;

DROP TABLE IF EXISTS t0;
DROP TABLE IF EXISTS t1;
DROP TABLE IF EXISTS t2;
DROP TABLE IF EXISTS t3;
CREATE TABLE t0(c0 INTEGER);
CREATE TABLE t1(c0 INTEGER);
CREATE TABLE t2(c0, c1 NOT NULL);
CREATE TABLE t3(c0 INTEGER);
SELECT * FROM sqlite_schema;

-- RESULT:r
-- RESULT:F77ED426335DE0E788057EAAF01BD2C8F186835CC80D45F416D1A66B4BF51797
SELECT hex(sha3_agg(sql)) as r FROM sqlite_schema;

-- RESULT:r
-- RESULT:118C9A7D89C7A5A4A672E28C5CB72A4CF434A7D3A3DD0FA73D57CAF6
SELECT hex(sha3_query('SELECT * FROM "people" NOT INDEXED',224)) as r;

VACUUM;

-- verify vacuum does not change SHA3 hash
-- RESULT:r
-- RESULT:118C9A7D89C7A5A4A672E28C5CB72A4CF434A7D3A3DD0FA73D57CAF6
SELECT hex(sha3_query('SELECT * FROM "people" NOT INDEXED',224)) as r;

-- RESULT:hash,tbl_name
-- RESULT:DEA315FB184B247FFB47E6D3CDDEFC6E22768816F5AA5DD3D89C393A,people
-- RESULT:7B51B05352F28A25062E3E1012119559585D00E3E7A9C1B844E2D48F,t0
-- RESULT:F5E6B00121434FF76CE92AD35251E3B98BA92B8338E7122C787770E5,t1
-- RESULT:886717C41BD9143C26F68799F4183A7E8D6E25DD6F7857F9468E2805,t2
-- RESULT:5789B4B3FE4A4C4A568BE4EF69662F3B9ABC29AF8204C4D53652CD74,t3
select hex(sha3_query('SELECT * FROM ' || tbl_name || ' NOT INDEXED order by 1',224)) AS hash, tbl_name
FROM (SELECT tbl_name FROM sqlite_master WHERE type = 'table' and tbl_name != 'timer');

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
