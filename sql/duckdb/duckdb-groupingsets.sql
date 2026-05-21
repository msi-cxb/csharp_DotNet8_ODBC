-- https://duckdb.org/docs/stable/sql/query_syntax/grouping_sets
-- https://people.sc.fsu.edu/~jburkardt/data/csv/addresses.csv

.echo on
-- .timer on
.conn duckdb

PRAGMA version;

.print addresses.csv is a really badly formatted csv file

.delete [[__DATAFOLDER__]]\addresses.csv

CREATE SEQUENCE seq_increment_20 START 80 INCREMENT BY 20;

-- get the file from the internet
COPY (SELECT * FROM read_csv('https://people.sc.fsu.edu/~jburkardt/data/csv/addresses.csv',skip=0,header=false,delim=',')) 
TO '[[__DATAFOLDER__]]\addresses.csv' (DELIMITER ',',HEADER false);

--RESULT:cnt
--RESULT:6
select count(1) as cnt from read_csv('https://people.sc.fsu.edu/~jburkardt/data/csv/addresses.csv',skip=0,header=false,delim=',');

-- add Income column
COPY (
    SELECT *, nextval('seq_increment_20')::INTEGER AS Income 
    FROM read_csv('https://people.sc.fsu.edu/~jburkardt/data/csv/addresses.csv',skip=0,header=false,delim=',')
) TO '[[__DATAFOLDER__]]\addresses.csv' ( HEADER false, DELIMITER ',');


-- sniff the csv file to see how DuckDB might handle the import...
.mode line
--RESULT:Prompt
 --RESULT:FROM read_csv('C:\Users\charlie\Desktop\sqliteodbc_testsql\csharp_ODBC\bin\Debug\net8.0\data\addresses.csv', auto_detect=false, delim=',', quote='"', escape='"', new_line='\n', skip=0, comment='', header=true, columns={'John': 'VARCHAR', 'Doe': 'VARCHAR', '120 jefferson st.': 'VARCHAR', 'Riverside': 'VARCHAR', 'NJ': 'VARCHAR', '08075': 'VARCHAR'});
SELECT Prompt FROM sniff_csv('[[__DATAFOLDER__]]\addresses.csv');

CREATE OR REPLACE TABLE addresses AS
    FROM read_csv(
        '[[__DATAFOLDER__]]\addresses.csv', 
        auto_detect=false, 
        strict_mode=false,
        null_padding=true,
        delim=',', 
        quote='"', 
        escape='"', 
        new_line='\n', 
        skip=0, 
        comment='', 
        header=false, 
        columns={
            'First': 'VARCHAR', 
            'Last': 'VARCHAR', 
            'street_name': 'VARCHAR', 
            'City': 'VARCHAR', 
            'State': 'VARCHAR', 
            'Zip': 'VARCHAR', 
            'Income': 'INTEGER'}
    );

-- https://duckdb.org/docs/stable/data/csv/overview#order-preservation
-- so the following does not need an order by

-- since Income is random, we exclude it from check
-- RESULT:First,Last,street_name,City,State,Zip,Income
-- RESULT:John,Doe,120 jefferson st.,Riverside, NJ, 08075,80
-- RESULT:Jack,McGinnis,220 hobo Av.,Phila, PA,09119,100
-- RESULT:John "Da Man",Repici,120 Jefferson St.,Riverside, NJ,08075,120
-- RESULT:Stephen,Tyler,7452 Terrace "At the Plaza" road,SomeTown,SD, 91234,140
-- RESULT:null,Blankman,null,SomeTown, SD, 00298,160
-- RESULT:Joan "the bone", Anne,Jet,9th, at Terrace plc,Desert City,CO,00123,180
SELECT * FROM addresses order by income;

-- addresses.csv doesn't have header, so another way to do this is define table first...
CREATE OR REPLACE TABLE addresses (
    First VARCHAR,
    Last VARCHAR,
    street_name VARCHAR,
    City VARCHAR,
    State VARCHAR,
    Zip VARCHAR,
    Income INTEGER
);
COPY addresses FROM '[[__DATAFOLDER__]]\addresses.csv';

-- RESULT:First,Last,street_name,City,State,Zip,Income
-- RESULT:John,Doe,120 jefferson st.,Riverside, NJ, 08075,80
-- RESULT:Jack,McGinnis,220 hobo Av.,Phila, PA,09119,100
-- RESULT:John "Da Man",Repici,120 Jefferson St.,Riverside, NJ,08075,120
-- RESULT:Stephen,Tyler,7452 Terrace "At the Plaza" road,SomeTown,SD, 91234,140
-- RESULT:null,Blankman,null,SomeTown, SD, 00298,160
-- RESULT:Joan "the bone", Anne,Jet,9th, at Terrace plc,Desert City,CO,00123,180
SELECT * FROM addresses order by income;

-- RESULT:City,street_name,avg(income)
-- RESULT:Desert City,9th, at Terrace plc,180
-- RESULT:Desert City,null,180
-- RESULT:Phila,220 hobo Av.,100
-- RESULT:Phila,null,100
-- RESULT:Riverside,120 Jefferson St.,120
-- RESULT:Riverside,120 jefferson st.,80
-- RESULT:Riverside,null,100
-- RESULT:SomeTown,7452 Terrace "At the Plaza" road,140
-- RESULT:SomeTown,null,150
-- RESULT:SomeTown,null,160
-- RESULT:null,120 Jefferson St.,120
-- RESULT:null,120 jefferson st.,80
-- RESULT:null,220 hobo Av.,100
-- RESULT:null,7452 Terrace "At the Plaza" road,140
-- RESULT:null,9th, at Terrace plc,180
-- RESULT:null,null,130
-- RESULT:null,null,160
SELECT city, street_name, avg(income)
FROM addresses
GROUP BY GROUPING SETS ((city, street_name), (city), (street_name), ())
order by city, street_name, avg(income);


-- RESULT:City,street_name,avg(income)
-- RESULT:Desert City,9th, at Terrace plc,180
-- RESULT:Desert City,null,180
-- RESULT:Phila,220 hobo Av.,100
-- RESULT:Phila,null,100
-- RESULT:Riverside,120 Jefferson St.,120
-- RESULT:Riverside,120 jefferson st.,80
-- RESULT:Riverside,null,100
-- RESULT:SomeTown,7452 Terrace "At the Plaza" road,140
-- RESULT:SomeTown,null,150
-- RESULT:SomeTown,null,160
-- RESULT:null,120 Jefferson St.,120
-- RESULT:null,120 jefferson st.,80
-- RESULT:null,220 hobo Av.,100
-- RESULT:null,7452 Terrace "At the Plaza" road,140
-- RESULT:null,9th, at Terrace plc,180
-- RESULT:null,null,130
-- RESULT:null,null,160
SELECT city, street_name, avg(income)
FROM addresses
GROUP BY CUBE (city, street_name)
order by city, street_name, avg(income);

-- RESULT:City,street_name,avg(income)
-- RESULT:Desert City,9th, at Terrace plc,180
-- RESULT:Desert City,null,180
-- RESULT:Phila,220 hobo Av.,100
-- RESULT:Phila,null,100
-- RESULT:Riverside,120 Jefferson St.,120
-- RESULT:Riverside,120 jefferson st.,80
-- RESULT:Riverside,null,100
-- RESULT:SomeTown,7452 Terrace "At the Plaza" road,140
-- RESULT:SomeTown,null,150
-- RESULT:SomeTown,null,160
-- RESULT:null,null,130
SELECT city, street_name, avg(income)
FROM addresses
GROUP BY ROLLUP (city, street_name)
order by city, street_name, avg(income);

-- new sample table for additional examples
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
