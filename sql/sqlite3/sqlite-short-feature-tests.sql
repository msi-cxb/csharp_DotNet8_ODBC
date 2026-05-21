.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite3_feature_tests
-- Description: Recent SQLite features - iif(), CREATE TABLE AS, ALTER TABLE DROP COLUMN
-- Source: sqlite3_feature_tests in sqliteODBC_tests.vbs (line 4436)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === sqlite3_feature_tests iif ===

-- RESULT:w,x,y,z
-- RESULT:false,true,false,true
SELECT iif(1=2,'true','false') AS w, iif(2=2,'true','false') AS x, iif('hello' = 'world','true','false') AS y, iif('same' = 'same','true','false') AS z;

.print === alter table drop column ===

DROP TABLE IF EXISTS people;
CREATE TABLE people (id INTEGER, income REAL, tax_rate REAL);

WITH RECURSIVE person(x) AS (
    SELECT 1 UNION ALL SELECT x+1 FROM person WHERE x < 1000
)
INSERT INTO people (id, income, tax_rate)
SELECT x, 70+mod(x,15)*3, (15.0+(mod(x,5)*0.2)+mod(x,15))/100. FROM person;

-- Note: expects 1 row
SELECT count(1) FROM people;

DROP TABLE IF EXISTS people_copy;
CREATE TABLE people_copy AS SELECT * FROM people;

-- Note: expects 1 row
SELECT count(1) FROM people_copy;

ALTER TABLE people_copy DROP COLUMN tax_rate;

-- Note: expects 1 row
SELECT * FROM people_copy LIMIT 1;

DROP TABLE IF EXISTS people_copy;

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
