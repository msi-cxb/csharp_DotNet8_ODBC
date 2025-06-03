.echo ON
.timer OFF

PRAGMA version;

.print generate the company table

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

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,ID,INTEGER,true,null,true
-- RESULT:1,NAME,VARCHAR,true,null,false
-- RESULT:2,AGE,INTEGER,true,null,false
-- RESULT:3,ADDRESS,VARCHAR,false,null,false
-- RESULT:4,SALARY,FLOAT,false,null,false
PRAGMA table_info('company');

.print generate the weather TABLE

DROP TABLE IF EXISTS weather;
        
CREATE TABLE weather ( 
    city           VARCHAR,
    temp_lo        INTEGER,
    temp_hi        INTEGER,
    prcp           REAL, 
    date           DATE 
);

.print generate the cities TABLE

DROP TABLE IF EXISTS cities;

CREATE TABLE cities (
    name            VARCHAR,
    lat             DECIMAL, 
    lon             DECIMAL 
);
      
.print note that hhmmss will be dropped as the column format is DATE

INSERT INTO weather VALUES ('San Francisco', 46, 50, 0.25, '1994-11-27 12:34:56');

INSERT INTO weather VALUES ('New York', 45, 50, 0.25, '1994-11-27 12:34:56');

INSERT INTO weather (city, temp_lo, temp_hi, prcp, date) 
	VALUES('San Francisco', 43, 57, 0.0, '1994-11-29 12:34:56');
    
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date) 
	VALUES('San Francisco', 39, 57, 0.0, '1994-11-29 12:34:56');
    
INSERT INTO weather (date, city, temp_hi, temp_lo) 
	VALUES ('1994-11-29 12:34:56', 'Hayward', 54, 37);
    
INSERT INTO cities VALUES ('San Francisco',1,1);

INSERT INTO cities VALUES ('New York',2,2);

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,city,VARCHAR,false,null,false
-- RESULT:1,temp_lo,INTEGER,false,null,false
-- RESULT:2,temp_hi,INTEGER,false,null,false
-- RESULT:3,prcp,FLOAT,false,null,false
-- RESULT:4,date,DATE,false,null,false
PRAGMA table_info('weather');

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,name,VARCHAR,false,null,false
-- RESULT:1,lat,DECIMAL(18,3),false,null,false
-- RESULT:2,lon,DECIMAL(18,3),false,null,false
PRAGMA table_info('cities');

-- RESULT:date
-- RESULT:19941127120000
-- RESULT:19941127120000
-- RESULT:19941129120000
-- RESULT:19941129120000
-- RESULT:19941129120000
select "date" from weather;

-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:San Francisco,46,50,0.25,19941127120000
-- RESULT:New York,45,50,0.25,19941127120000
-- RESULT:San Francisco,43,57,0,19941129120000
-- RESULT:San Francisco,39,57,0,19941129120000
-- RESULT:Hayward,37,54,null,19941129120000
select * from weather;
        
-- RESULT:count_star()
-- RESULT:5
select count(*) from weather;
        
-- RESULT:city,temp_avg,date
-- RESULT:San Francisco,48,19941127120000
-- RESULT:New York,47.5,19941127120000
-- RESULT:San Francisco,50,19941129120000
-- RESULT:San Francisco,48,19941129120000
-- RESULT:Hayward,45.5,19941129120000
SELECT city, (temp_hi+temp_lo)/2 AS temp_avg, date FROM weather;

-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:San Francisco,46,50,0.25,19941127120000
SELECT * FROM weather WHERE city = 'San Francisco' AND prcp > 0.0;
        
-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:Hayward,37,54,null,19941129120000
-- RESULT:New York,45,50,0.25,19941127120000
-- RESULT:San Francisco,46,50,0.25,19941127120000
-- RESULT:San Francisco,43,57,0,19941129120000
-- RESULT:San Francisco,39,57,0,19941129120000
SELECT * FROM weather ORDER BY city;
        
-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:Hayward,37,54,null,19941129120000
-- RESULT:New York,45,50,0.25,19941127120000
-- RESULT:San Francisco,39,57,0,19941129120000
-- RESULT:San Francisco,43,57,0,19941129120000
-- RESULT:San Francisco,46,50,0.25,19941127120000
SELECT * FROM weather ORDER BY city, temp_lo;
        
-- RESULT:city
-- RESULT:Hayward
-- RESULT:New York
-- RESULT:San Francisco
SELECT DISTINCT city FROM weather ORDER BY city;

-- RESULT:
SELECT * FROM weather, cities WHERE city = 'hayward';

-- RESULT:
SELECT city, temp_lo, temp_hi, prcp, date, lon, lat FROM weather, cities WHERE city = 'hayward';

-- RESULT:city,temp_lo,temp_hi,prcp,date,lon,lat
-- RESULT:San Francisco,46,50,0.25,19941127120000,1.000,1.000
-- RESULT:New York,45,50,0.25,19941127120000,2.000,2.000
-- RESULT:San Francisco,43,57,0,19941129120000,1.000,1.000
-- RESULT:San Francisco,39,57,0,19941129120000,1.000,1.000
SELECT weather.city, weather.temp_lo, weather.temp_hi, weather.prcp, weather.date, cities.lon, cities.lat FROM weather, cities WHERE cities.name = weather.city;
        
-- RESULT:city,temp_lo,temp_hi,prcp,date,name,lat,lon
-- RESULT:San Francisco,46,50,0.25,19941127120000,San Francisco,1.000,1.000
-- RESULT:New York,45,50,0.25,19941127120000,New York,2.000,2.000
-- RESULT:San Francisco,43,57,0,19941129120000,San Francisco,1.000,1.000
-- RESULT:San Francisco,39,57,0,19941129120000,San Francisco,1.000,1.000
SELECT * FROM weather INNER JOIN cities ON (weather.city = cities.name);

-- RESULT:city,temp_lo,temp_hi,prcp,date,name,lat,lon
-- RESULT:San Francisco,46,50,0.25,19941127120000,San Francisco,1.000,1.000
-- RESULT:New York,45,50,0.25,19941127120000,New York,2.000,2.000
-- RESULT:San Francisco,43,57,0,19941129120000,San Francisco,1.000,1.000
-- RESULT:San Francisco,39,57,0,19941129120000,San Francisco,1.000,1.000
-- RESULT:Hayward,37,54,null,19941129120000,null,null,null
SELECT * FROM weather LEFT OUTER JOIN cities ON (weather.city = cities.name);
        
-- RESULT:max(temp_lo)
-- RESULT:46
SELECT max(temp_lo) FROM weather;
        
-- RESULT:city
-- RESULT:San Francisco
SELECT city FROM weather WHERE temp_lo = (SELECT max(temp_lo) FROM weather);
        
-- RESULT:city,max(temp_lo)
-- RESULT:Hayward,37
-- RESULT:New York,45
-- RESULT:San Francisco,46
SELECT city, max(temp_lo) FROM weather GROUP BY city ORDER BY city;

-- RESULT:city,max(temp_lo)
-- RESULT:Hayward,37
-- RESULT:San Francisco,46
SELECT city, max(temp_lo) FROM weather GROUP BY city HAVING min(temp_lo) < 40 ORDER BY city;

-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:San Francisco,46,50,0.25,19941127120000
-- RESULT:San Francisco,43,57,0,19941129120000
-- RESULT:San Francisco,39,57,0,19941129120000
SELECT * FROM weather WHERE city LIKE 'S%';

-- RESULT:city,min(temp_lo)
-- RESULT:San Francisco,39
SELECT city, min(temp_lo) FROM weather WHERE city LIKE 'S%' GROUP BY city HAVING min(temp_lo) < 40;
        
UPDATE weather SET temp_hi = temp_hi - 2,  temp_lo = temp_lo - 2 WHERE date > '1994-11-28';
        
-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:San Francisco,46,50,0.25,19941127120000
-- RESULT:New York,45,50,0.25,19941127120000
-- RESULT:San Francisco,41,55,0,19941129120000
-- RESULT:San Francisco,37,55,0,19941129120000
-- RESULT:Hayward,35,52,null,19941129120000
SELECT * FROM weather;
        
DELETE FROM weather WHERE city = 'Hayward';
        
-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:San Francisco,46,50,0.25,19941127120000
-- RESULT:New York,45,50,0.25,19941127120000
-- RESULT:San Francisco,41,55,0,19941129120000
-- RESULT:San Francisco,37,55,0,19941129120000
SELECT * FROM weather;

.print create a people table using recursive CTE
.print note that current_localtimestamp() will be the same for all records as
.print they are all part of the same transaction and hence
.print the value of delta will be 00:00:00

create or replace table people (id INTEGER, income REAL, tax_rate REAL, t DATETIME );

WITH RECURSIVE person(x) AS ( 
    SELECT 1 UNION ALL SELECT x+1 FROM person where x < 10000
) 
INSERT INTO people ( id, income, tax_rate, t) 
    SELECT x, 70+mod(x,15)*3, (15.0+(mod(x,5)*0.2)+mod(x,15))/100., current_localtimestamp() FROM person;

-- RESULT:delta,cnt
-- RESULT:00:00:00,10000
SELECT max(t)-min(t) as delta, count(1) as cnt from people;


