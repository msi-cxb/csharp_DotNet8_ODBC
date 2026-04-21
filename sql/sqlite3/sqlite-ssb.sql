.echo on
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
ATTACH DATABASE '.\data\ssb-small.db' as ssb;
.print ATTACH

ANALYZE;

SELECT * FROM sqlite_stat1;

.print === Q1.1 ===

-- RESULT:revenue
-- RESULT:null
SELECT sum(lo_extendedprice*lo_discount)*1.0 AS revenue
FROM ssb.lineorder, ssb.date
WHERE lo_orderdate = d_datekey
  AND d_year = 1993
  AND lo_discount BETWEEN 1 AND 3
  AND lo_quantity < 25;

.print === Q1.2 ===

-- RESULT:revenue
-- RESULT:null
SELECT sum(lo_extendedprice*lo_discount)*1.0 AS revenue
FROM ssb.lineorder, ssb.date
WHERE lo_orderdate = d_datekey
  AND d_yearmonthnum = 199401
  AND lo_quantity BETWEEN 26 AND 35
  AND lo_discount BETWEEN 4 AND 6;

.print === Q1.3 ===

-- RESULT:revenue
-- RESULT:null
SELECT sum(lo_extendedprice*lo_discount)*1.0 AS revenue
FROM ssb.lineorder, ssb.date
WHERE lo_orderdate = d_datekey
  AND d_weeknuminyear = 6
  AND d_year = 1994
  AND lo_quantity BETWEEN 36 AND 40
  AND lo_discount BETWEEN 5 AND 7;

.print === Q2.1 ===

-- RESULT:sum(lo_revenue),d_year,p_brand1
-- RESULT:2383108,1992,MFGR#1210
-- RESULT:1673756,1992,MFGR#1211
-- RESULT:4277213,1992,MFGR#1218
-- RESULT:6085242,1992,MFGR#1238
-- RESULT:2110015,1992,MFGR#1239
-- RESULT:1866783,1992,MFGR#127
SELECT sum(lo_revenue), d_year, p_brand1
FROM ssb.lineorder, ssb.date, ssb.part, ssb.supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND s_region = 'AMERICA'
GROUP BY d_year, p_brand1
ORDER BY d_year, p_brand1;

.print === Q2.2 ===

-- RESULT:sum(lo_revenue),d_year,p_brand1
-- RESULT:2383108,1992,MFGR#1210
-- RESULT:1673756,1992,MFGR#1211
-- RESULT:4277213,1992,MFGR#1218
-- RESULT:6085242,1992,MFGR#1238
-- RESULT:2110015,1992,MFGR#1239
-- RESULT:1866783,1992,MFGR#127
SELECT sum(lo_revenue), d_year, p_brand1
FROM ssb.lineorder, ssb.date, ssb.part, ssb.supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND p_brand1 BETWEEN 'MFGR#1' AND 'MFGR#300'
  AND s_region = 'AMERICA'
GROUP BY d_year, p_brand1
ORDER BY d_year, p_brand1;

.print === Q2.3 ===

SELECT sum(lo_revenue), d_year, p_brand1
FROM ssb.lineorder, ssb.date, ssb.part, ssb.supplier
WHERE lo_orderdate = d_datekey
  AND lo_partkey = p_partkey
  AND lo_suppkey = s_suppkey
  AND p_category = 'MFGR#12'
  AND p_brand1 = 'MFGR#2339'
  AND s_region = 'AMERICA'
GROUP BY d_year, p_brand1
ORDER BY d_year, p_brand1;

.print === Q3.1 ===

-- RESULT:c_nation,s_nation,d_year,revenue
-- RESULT:INDIA,INDIA,1992,23732578
-- RESULT:VIETNAM,CHINA,1992,20207704
-- RESULT:CHINA,INDIA,1992,16929264
-- RESULT:VIETNAM,INDIA,1992,8909052
-- RESULT:JAPAN,INDIA,1992,5747879
-- RESULT:INDONESIA,INDIA,1992,3694778
-- RESULT:CHINA,CHINA,1992,3566927
SELECT c_nation, s_nation, d_year, sum(lo_revenue)*1.0 AS revenue
FROM ssb.customer, ssb.lineorder, ssb.supplier, ssb.date
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_orderdate = d_datekey
  AND c_region = 'ASIA'
  AND s_region = 'ASIA'
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_nation, s_nation, d_year
ORDER BY d_year ASC, revenue DESC;

.print === Q3.2 ===

SELECT c_city, s_city, d_year, sum(lo_revenue)*1.0 AS revenue
FROM ssb.customer, ssb.lineorder, ssb.supplier, ssb.date
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_orderdate = d_datekey
  AND c_nation = 'UNITED STATES'
  AND s_nation = 'UNITED STATES'
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_city, s_city, d_year
ORDER BY d_year ASC, revenue DESC;

.print === Q3.3 ===

SELECT c_city, s_city, d_year, sum(lo_revenue)*1.0 AS revenue
FROM ssb.customer, ssb.lineorder, ssb.supplier, ssb.date
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_orderdate = d_datekey
  AND (c_city='UNITED KI1' OR c_city='UNITED KI5')
  AND (s_city='UNITED KI1' OR s_city='UNITED KI5')
  AND d_year >= 1992 AND d_year <= 1997
GROUP BY c_city, s_city, d_year
ORDER BY d_year ASC, revenue DESC;

.print === Q3.4 ===

SELECT c_city, s_city, d_year, sum(lo_revenue)*1.0 AS revenue
FROM ssb.customer, ssb.lineorder, ssb.supplier, ssb.date
WHERE lo_custkey = c_custkey
  AND lo_suppkey = s_suppkey
  AND lo_orderdate = d_datekey
  AND (c_city='UNITED KI1' OR c_city='UNITED KI5')
  AND (s_city='UNITED KI1' OR s_city='UNITED KI5')
  AND d_yearmonth = 'Dec1997'
GROUP BY c_city, s_city, d_year
ORDER BY d_year ASC, revenue DESC;

.print === Q4.1 ===

-- RESULT:d_year,c_nation,profit
-- RESULT:1992,ARGENTINA,10986527
-- RESULT:1992,CANADA,21843842
-- RESULT:1992,PERU,9912005
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
ORDER BY d_year, c_nation;

.print === Q4.2 ===

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
ORDER BY d_year, s_nation, p_category;

.print === Q4.3 ===

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
ORDER BY d_year, s_city, p_brand1;

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
