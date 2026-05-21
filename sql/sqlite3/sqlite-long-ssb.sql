-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_ssb
-- Description: Star Schema Benchmark (SSB) analytics queries against ssb_1.sqlite3
-- Source: sqlite_ssb in sqliteODBC_tests.vbs (line 612)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_ssb ===

.print ATTACH
ATTACH DATABASE '.\data\ssb-sf1.db' as ssb;
.print ATTACH

ANALYZE;

.echo on

SELECT * FROM sqlite_stat1;

.print === Q1.1 ===

-- RESULT:revenue
-- RESULT:445921715901
SELECT sum(lo_extendedprice*lo_discount)*1.0 AS revenue
FROM ssb.lineorder, ssb.date
WHERE lo_orderdate = d_datekey
  AND d_year = 1993
  AND lo_discount BETWEEN 1 AND 3
  AND lo_quantity < 25
LIMIT 5;

.print === Q1.2 ===

-- RESULT:revenue
-- RESULT:97884685311
SELECT sum(lo_extendedprice*lo_discount)*1.0 AS revenue
FROM ssb.lineorder, ssb.date
WHERE lo_orderdate = d_datekey
  AND d_yearmonthnum = 199401
  AND lo_quantity BETWEEN 26 AND 35
  AND lo_discount BETWEEN 4 AND 6
LIMIT 5;

.print === Q1.3 ===

-- RESULT:revenue
-- RESULT:15834374216
SELECT sum(lo_extendedprice*lo_discount)*1.0 AS revenue
FROM ssb.lineorder, ssb.date
WHERE lo_orderdate = d_datekey
  AND d_weeknuminyear = 6
  AND d_year = 1994
  AND lo_quantity BETWEEN 36 AND 40
  AND lo_discount BETWEEN 5 AND 7;

.print === Q2.1 ===

-- RESULT:sum(lo_revenue),d_year,p_brand1
-- RESULT:592914893,1992,MFGR#121
-- RESULT:611911098,1992,MFGR#1210
-- RESULT:531543320,1992,MFGR#1211
-- RESULT:662211110,1992,MFGR#1212
-- RESULT:718801005,1992,MFGR#1213
SELECT sum(lo_revenue), d_year, p_brand1
FROM ssb.lineorder, ssb.date, ssb.part, ssb.supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND s_region = 'AMERICA'
GROUP BY d_year, p_brand1
ORDER BY d_year, p_brand1
LIMIT 5;

.print === Q2.2 ===

-- RESULT:sum(lo_revenue),d_year,p_brand1
-- RESULT:592914893,1992,MFGR#121
-- RESULT:611911098,1992,MFGR#1210
-- RESULT:531543320,1992,MFGR#1211
-- RESULT:662211110,1992,MFGR#1212
-- RESULT:718801005,1992,MFGR#1213
SELECT sum(lo_revenue), d_year, p_brand1
FROM ssb.lineorder, ssb.date, ssb.part, ssb.supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND p_brand1 BETWEEN 'MFGR#1' AND 'MFGR#300'
  AND s_region = 'AMERICA'
GROUP BY d_year, p_brand1
ORDER BY d_year, p_brand1
LIMIT 5;

.print === Q2.3 ===

-- no result?
SELECT sum(lo_revenue), d_year, p_brand1
FROM ssb.lineorder, ssb.date, ssb.part, ssb.supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND p_brand1 = 'MFGR#2339'
  AND s_region = 'AMERICA'
GROUP BY d_year, p_brand1
ORDER BY d_year, p_brand1
LIMIT 5;

.print === Q3.1 ===

-- RESULT:c_nation,s_nation,d_year,revenue
-- RESULT:INDONESIA,CHINA,1992,6832245482
-- RESULT:CHINA,CHINA,1992,6709651479
-- RESULT:CHINA,INDONESIA,1992,6577537133
-- RESULT:INDIA,CHINA,1992,6293157658
-- RESULT:VIETNAM,INDONESIA,1992,6291577840
SELECT c_nation, s_nation, d_year, sum(lo_revenue)*1.0 AS revenue
FROM ssb.customer, ssb.lineorder, ssb.supplier, ssb.date
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_orderdate = d_datekey
  AND c_region = 'ASIA'
  AND s_region = 'ASIA'
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_nation, s_nation, d_year
ORDER BY d_year ASC, revenue DESC
LIMIT 5;

.print === Q3.2 ===

-- RESULT:c_city,s_city,d_year,revenue
-- RESULT:UNITED ST5,UNITED ST4,1992,110092110
-- RESULT:UNITED ST9,UNITED ST5,1992,103120483
-- RESULT:UNITED ST7,UNITED ST4,1992,101924731
-- RESULT:UNITED ST8,UNITED ST9,1992,101412151
-- RESULT:UNITED ST3,UNITED ST4,1992,96314533
SELECT c_city, s_city, d_year, sum(lo_revenue)*1.0 AS revenue
FROM ssb.customer, ssb.lineorder, ssb.supplier, ssb.date
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_orderdate = d_datekey
  AND c_nation = 'UNITED STATES'
  AND s_nation = 'UNITED STATES'
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_city, s_city, d_year
ORDER BY d_year ASC, revenue DESC
LIMIT 5;

.print === Q3.3 ===

-- RESULT:c_city,s_city,d_year,revenue
-- RESULT:UNITED KI5,UNITED KI5,1992,65017072
-- RESULT:UNITED KI1,UNITED KI5,1992,50106364
-- RESULT:UNITED KI5,UNITED KI1,1992,46834558
-- RESULT:UNITED KI1,UNITED KI1,1992,41852567
-- RESULT:UNITED KI5,UNITED KI1,1993,96560478
SELECT c_city, s_city, d_year, sum(lo_revenue)*1.0 AS revenue
FROM ssb.customer, ssb.lineorder, ssb.supplier, ssb.date
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_orderdate = d_datekey
  AND (c_city='UNITED KI1' OR c_city='UNITED KI5')
  AND (s_city='UNITED KI1' OR s_city='UNITED KI5')
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_city, s_city, d_year
ORDER BY d_year ASC, revenue DESC
LIMIT 5;

.print === Q3.4 ===

-- RESULT:c_city,s_city,d_year,revenue
-- RESULT:UNITED KI1,UNITED KI5,1997,7816232
-- RESULT:UNITED KI5,UNITED KI5,1997,5437434
-- RESULT:UNITED KI5,UNITED KI1,1997,2660888
SELECT c_city, s_city, d_year, sum(lo_revenue)*1.0 AS revenue
FROM ssb.customer, ssb.lineorder, ssb.supplier, ssb.date
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_orderdate = d_datekey
  AND (c_city='UNITED KI1' OR c_city='UNITED KI5')
  AND (s_city='UNITED KI1' OR s_city='UNITED KI5')
  AND d_yearmonth = 'Dec1997'
GROUP BY c_city, s_city, d_year
ORDER BY d_year ASC, revenue DESC
LIMIT 5;

.print === Q4.1 ===

-- RESULT:d_year,c_nation,profit
-- RESULT:1992,ARGENTINA,9590071009
-- RESULT:1992,BRAZIL,9133600981
-- RESULT:1992,CANADA,10075046297
-- RESULT:1992,PERU,9373187270
-- RESULT:1992,UNITED STATES,9945405000
SELECT d_year, c_nation, sum(lo_revenue - lo_supplycost)*1.0 AS profit
FROM ssb.date, ssb.customer, ssb.supplier, ssb.part, ssb.lineorder
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_partkey = p_partkey
  AND lo_orderdate = d_datekey
  AND c_region = 'AMERICA'
  AND s_region = 'AMERICA'
  AND (p_mfgr = 'MFGR#1' OR p_mfgr = 'MFGR#2')
GROUP BY d_year, c_nation
ORDER BY d_year, c_nation
LIMIT 5;

.print === Q4.2 ===

-- RESULT:d_year,s_nation,p_category,profit
-- RESULT:1997,ARGENTINA,MFGR#11,1023857902
-- RESULT:1997,ARGENTINA,MFGR#12,968432364
-- RESULT:1997,ARGENTINA,MFGR#13,928495231
-- RESULT:1997,ARGENTINA,MFGR#14,911250730
-- RESULT:1997,ARGENTINA,MFGR#15,883458605
SELECT d_year, s_nation, p_category, sum(lo_revenue - lo_supplycost)*1.0 AS profit
FROM date, ssb.customer, ssb.supplier, ssb.part, ssb.lineorder
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_partkey = p_partkey
  AND lo_orderdate = d_datekey
  AND c_region = 'AMERICA'
  AND s_region = 'AMERICA'
  AND (d_year = 1997 OR d_year = 1998)
  AND (p_mfgr = 'MFGR#1' OR p_mfgr = 'MFGR#2')
GROUP BY d_year, s_nation, p_category
ORDER BY d_year, s_nation, p_category
LIMIT 5;

.print === Q4.3 ===

-- RESULT:d_year,s_city,p_brand1,profit
-- RESULT:1997,UNITED ST0,MFGR#1411,5174140
-- RESULT:1997,UNITED ST0,MFGR#1413,3518450
-- RESULT:1997,UNITED ST0,MFGR#1418,5806056
-- RESULT:1997,UNITED ST0,MFGR#1419,348334
-- RESULT:1997,UNITED ST0,MFGR#1420,7395632
SELECT d_year, s_city, p_brand1, sum(lo_revenue - lo_supplycost)*1.0 AS profit
FROM ssb.date, ssb.customer, ssb.supplier, ssb.part, ssb.lineorder
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_partkey = p_partkey
  AND lo_orderdate = d_datekey
  AND c_region = 'AMERICA'
  AND s_nation = 'UNITED STATES'
  AND (d_year = 1997 OR d_year = 1998)
  AND p_category = 'MFGR#14'
GROUP BY d_year, s_city, p_brand1
ORDER BY d_year, s_city, p_brand1
LIMIT 5;

.echo off

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
