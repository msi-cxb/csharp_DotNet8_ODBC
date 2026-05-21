.echo on
-- .timer on
.conn duckdb

.delete [[__DATAFOLDER__]]\weather.csv

drop table if exists company;

CREATE TABLE COMPANY(
	ID             INT			NOT NULL     PRIMARY KEY,
	NAME           TEXT			NOT NULL,
	AGE            INT			NOT NULL,
	ADDRESS        CHAR(50),
	SALARY         REAL
);

INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
	VALUES
		(1, 'Paul', 32, 'California', 20000.00),
		(2, 'Allen', 25, 'Texas', 15000.00),
		(3, 'Teddy', 23, 'Norway', 20000.00),
		(4, 'Mark', 25, 'Rich-Mond ', 65000.00),
		(5, 'David', 27, 'Texas', 85000.00),
		(6, 'Kim', 22, 'South-Hall', 45000.00);

-- RESULT:ID,NAME,AGE,ADDRESS,SALARY
-- RESULT:1,Paul,32,California,20000
-- RESULT:2,Allen,25,Texas,15000
-- RESULT:3,Teddy,23,Norway,20000
-- RESULT:4,Mark,25,Rich-Mond ,65000
-- RESULT:5,David,27,Texas,85000
-- RESULT:6,Kim,22,South-Hall,45000
select * from company;

CREATE OR REPLACE TABLE weather AS FROM 'https://duckdb.org/data/weather.csv';
COPY (SELECT * FROM weather) TO './data/weather.csv' (FORMAT csv, HEADER);

-- RESULT:cnt
-- RESULT:3
SELECT count(1) as cnt FROM read_csv_auto('[[__DATAFOLDER__]]\weather.csv');

-- overwrite the weather file with company data...includes header 
.output [[__DATAFOLDER__]]\weather.csv
select * from company;
.output

-- RESULT:cnt
-- RESULT:6
SELECT count(1) as cnt FROM read_csv_auto('[[__DATAFOLDER__]]\weather.csv');

 