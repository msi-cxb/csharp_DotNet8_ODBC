.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite_simple_virtual_columns
-- Description: Generated/virtual columns - computed column for tax calculation
-- Source: sqlite_simple_virtual_columns in sqliteODBC_tests.vbs (line 2700)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite_simple_virtual_columns ===

CREATE TABLE people (id INTEGER, income REAL, tax_rate REAL);

WITH RECURSIVE person(x) AS (
    SELECT 1 UNION ALL SELECT x+1 FROM person WHERE x < 100000
)
INSERT INTO people (id, income, tax_rate)
SELECT x, 70+mod(x,15)*3, (15.0+(mod(x,5)*0.2)+mod(x,15))/100. FROM person;

-- RESULT:numPeople,minIncome,maxIncome,minTaxRate,maxTaxRate
-- RESULT:100000,70,112,0.15,0.298
SELECT count(1) AS numPeople, min(income) AS minIncome, max(income) AS maxIncome, min(tax_rate) AS minTaxRate, max(tax_rate) AS maxTaxRate FROM people;

ALTER TABLE people ADD COLUMN tax REAL AS (income * tax_rate);

-- Note: expects 10 rows
-- RESULT:id,income,tax_rate,tax
-- RESULT:1,73,0.162,11.83
-- RESULT:2,76,0.174,13.22
-- RESULT:3,79,0.186,14.69
-- RESULT:4,82,0.198,16.24
-- RESULT:5,85,0.2,17
-- RESULT:6,88,0.212,18.66
-- RESULT:7,91,0.224,20.38
-- RESULT:8,94,0.236,22.18
-- RESULT:9,97,0.248,24.06
-- RESULT:10,100,0.25,25
SELECT id, income, tax_rate, round(tax,2) AS tax FROM people LIMIT 10;

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
