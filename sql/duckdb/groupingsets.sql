-- https://duckdb.org/docs/stable/sql/query_syntax/grouping_sets

.echo on
-- .timer on
.conn duckdb

.print DuckDB version string
-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.1,b390a7c376,Andium
PRAGMA version;

-- addresses.csv doesn't have header, so define table first
CREATE TABLE addresses (
    First VARCHAR,
    Last VARCHAR,
    street_name VARCHAR,
    City VARCHAR,
    State VARCHAR,
    Zip VARCHAR,
    Income INT
);

COPY addresses FROM '[[__DATAFOLDER__]]\addresses.csv';

-- RESULT:First,Last,street_name,City,State,Zip,Income
-- RESULT:John,Doe,120 jefferson st.,Riverside, NJ, 08075,110
-- RESULT:Jack,McGinnis,220 hobo Av.,Phila, PA,09119,130
-- RESULT:John "Da Man",Repici,120 Jefferson St.,Riverside, NJ,08075,100
-- RESULT:Stephen,Tyler,7452 Terrace "At the Plaza" road,SomeTown,SD, ,120
-- RESULT:null,Blankman,null,SomeTown, SD, 00298,100
-- RESULT:Joan "the bone", Anne,Jet,9th, at Terrace plc,Desert City,CO,00123,120
SELECT * FROM addresses;

-- the syntax () denotes the empty set (i.e., computing an ungrouped aggregate)
-- RESULT:City,street_name,avg(income)
-- RESULT:Desert City,9th, at Terrace plc,120
-- RESULT:Desert City,null,120
-- RESULT:Phila,220 hobo Av.,130
-- RESULT:Phila,null,130
-- RESULT:Riverside,120 Jefferson St.,100
-- RESULT:Riverside,120 jefferson st.,110
-- RESULT:Riverside,null,105
-- RESULT:SomeTown,7452 Terrace "At the Plaza" road,120
-- RESULT:SomeTown,null,100
-- RESULT:SomeTown,null,110
-- RESULT:null,120 Jefferson St.,100
-- RESULT:null,120 jefferson st.,110
-- RESULT:null,220 hobo Av.,130
-- RESULT:null,7452 Terrace "At the Plaza" road,120
-- RESULT:null,9th, at Terrace plc,120
-- RESULT:null,null,100
-- RESULT:null,null,113.33333333333333
SELECT city, street_name, avg(income)
FROM addresses
GROUP BY GROUPING SETS ((city, street_name), (city), (street_name), ())
order by city, street_name, avg(income);

-- RESULT:City,street_name,avg(income)
-- RESULT:Desert City,9th, at Terrace plc,120
-- RESULT:Desert City,null,120
-- RESULT:Phila,220 hobo Av.,130
-- RESULT:Phila,null,130
-- RESULT:Riverside,120 Jefferson St.,100
-- RESULT:Riverside,120 jefferson st.,110
-- RESULT:Riverside,null,105
-- RESULT:SomeTown,7452 Terrace "At the Plaza" road,120
-- RESULT:SomeTown,null,100
-- RESULT:SomeTown,null,110
-- RESULT:null,120 Jefferson St.,100
-- RESULT:null,120 jefferson st.,110
-- RESULT:null,220 hobo Av.,130
-- RESULT:null,7452 Terrace "At the Plaza" road,120
-- RESULT:null,9th, at Terrace plc,120
-- RESULT:null,null,100
-- RESULT:null,null,113.33333333333333
SELECT city, street_name, avg(income)
FROM addresses
GROUP BY CUBE (city, street_name)
order by city, street_name, avg(income);

-- RESULT:City,street_name,avg(income)
-- RESULT:Desert City,9th, at Terrace plc,120
-- RESULT:Desert City,null,120
-- RESULT:Phila,220 hobo Av.,130
-- RESULT:Phila,null,130
-- RESULT:Riverside,120 Jefferson St.,100
-- RESULT:Riverside,120 jefferson st.,110
-- RESULT:Riverside,null,105
-- RESULT:SomeTown,7452 Terrace "At the Plaza" road,120
-- RESULT:SomeTown,null,100
-- RESULT:SomeTown,null,110
-- RESULT:null,null,113.33333333333333
SELECT city, street_name, avg(income)
FROM addresses
GROUP BY ROLLUP (city, street_name)
order by city, street_name, avg(income);

CREATE TABLE students (course VARCHAR, type VARCHAR);
INSERT INTO students (course, type)
VALUES
    ('CS', 'Bachelor'), ('CS', 'Bachelor'), ('CS', 'PhD'), ('Math', 'Masters'),
    ('CS', NULL), ('CS', NULL), ('Math', NULL);

-- RESULT:course,type,count_star()
-- RESULT:CS,Bachelor,2
-- RESULT:CS,PhD,1
-- RESULT:CS,null,2
-- RESULT:CS,null,5
-- RESULT:Math,Masters,1
-- RESULT:Math,null,1
-- RESULT:Math,null,2
-- RESULT:null,Bachelor,2
-- RESULT:null,Masters,1
-- RESULT:null,PhD,1
-- RESULT:null,null,3
-- RESULT:null,null,7
SELECT course, type, count(*)
FROM students
GROUP BY GROUPING SETS ((course, type), course, type, ())
order by course, type, count(*);

SELECT course, type, count(*)
FROM students
GROUP BY course, type
UNION ALL
SELECT NULL AS course, type, count(*)
FROM students
GROUP BY type
UNION ALL
SELECT course, NULL AS type, count(*)
FROM students
GROUP BY course
UNION ALL
SELECT NULL AS course, NULL AS type, count(*)
FROM students;

-- RESULT:y,q,m,grouping_id()
-- RESULT:2023,1,1,0
-- RESULT:2023,1,2,0
-- RESULT:2023,1,3,0
-- RESULT:2023,1,null,1
-- RESULT:2023,2,4,0
-- RESULT:2023,2,5,0
-- RESULT:2023,2,6,0
-- RESULT:2023,2,null,1
-- RESULT:2023,3,7,0
-- RESULT:2023,3,8,0
-- RESULT:2023,3,9,0
-- RESULT:2023,3,null,1
-- RESULT:2023,4,10,0
-- RESULT:2023,4,11,0
-- RESULT:2023,4,12,0
-- RESULT:2023,4,null,1
-- RESULT:2023,null,null,3
-- RESULT:null,null,null,7
WITH days AS (
    SELECT
        year("generate_series")    AS y,
        quarter("generate_series") AS q,
        month("generate_series")   AS m
    FROM generate_series(DATE '2023-01-01', DATE '2023-12-31', INTERVAL 1 DAY)
)
SELECT y, q, m, GROUPING_ID(y, q, m) AS "grouping_id()"
FROM days
GROUP BY GROUPING SETS (
    (y, q, m),
    (y, q),
    (y),
    ()
)
ORDER BY y, q, m;

-- RESULT:y,q,m,grouping_id(y, q, m),y_q_m_bits
-- RESULT:2023,1,1,0,000
-- RESULT:2023,1,2,0,000
-- RESULT:2023,1,3,0,000
-- RESULT:2023,1,null,1,001
-- RESULT:2023,2,4,0,000
-- RESULT:2023,2,5,0,000
-- RESULT:2023,2,6,0,000
-- RESULT:2023,2,null,1,001
-- RESULT:2023,3,7,0,000
-- RESULT:2023,3,8,0,000
-- RESULT:2023,3,9,0,000
-- RESULT:2023,3,null,1,001
-- RESULT:2023,4,10,0,000
-- RESULT:2023,4,11,0,000
-- RESULT:2023,4,12,0,000
-- RESULT:2023,4,null,1,001
-- RESULT:2023,null,null,3,011
-- RESULT:null,null,null,7,111
WITH days AS (
    SELECT
        year("generate_series")    AS y,
        quarter("generate_series") AS q,
        month("generate_series")   AS m
    FROM generate_series(DATE '2023-01-01', DATE '2023-12-31', INTERVAL 1 DAY)
)
SELECT
    y, q, m,
    GROUPING_ID(y, q, m) AS "grouping_id(y, q, m)",
    right(GROUPING_ID(y, q, m)::BIT::VARCHAR, 3) AS "y_q_m_bits"
FROM days
GROUP BY GROUPING SETS (
    (y, q, m),
    (y, q),
    (y),
    ()
)
ORDER BY y, q, m;



