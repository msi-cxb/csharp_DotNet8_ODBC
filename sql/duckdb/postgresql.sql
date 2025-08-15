-- .echo on
-- .timer on
.conn duckdb

INSTALL postgres;
LOAD postgres;

CREATE SECRET postgres_secret_one (
    TYPE postgres,
    HOST 'charlies-MacBook-Pro.local',
    PORT 5432,
    DATABASE 'postgres',
    USER 'postgres',
    PASSWORD 'postgres'
);

.print ***************************
.print attach to postgres_db using SECRET
ATTACH '' AS postgres_db (TYPE postgres, SECRET postgres_secret_one);

-- just in case...
CREATE SCHEMA IF NOT EXISTS postgres_db.public;

-- RESULT:library_version,source_id,codename
-- RESULT:v1.3.2,0b83e5d2f6,Ossivalis
PRAGMA version;

-- should be empty (e.g. no results)
PRAGMA show_tables;

CREATE OR REPLACE TABLE postgres_db.tbl (id INTEGER, name VARCHAR);
INSERT INTO postgres_db.tbl VALUES (42, 'DuckDB');

-- RESULT:id,name
-- RESULT:42,DuckDB
SELECT * from postgres_db.tbl;

DROP TABLE IF EXISTS postgres_db.tbl;

-- should be empty (e.g. no results)
PRAGMA show_tables;

DETACH postgres_db;

.print ***************************
.print attach to postgres_db using connection string
ATTACH 'dbname=postgres user=postgres password=postgres host=charlies-MacBook-Pro.local port=5432' AS postgres_db (TYPE postgres);
        
CREATE OR REPLACE TABLE postgres_db.weather ( 
    city           VARCHAR,
    temp_lo        INTEGER,
    temp_hi        INTEGER,
    prcp           REAL, 
    date           DATE 
);

CREATE OR REPLACE TABLE postgres_db.cities (
    name            VARCHAR,
    lat             DECIMAL, 
    lon             DECIMAL 
);

INSERT INTO postgres_db.weather VALUES ('San Francisco', 46, 50, 0.25, '1994-11-27 12:34:56');

INSERT INTO postgres_db.weather VALUES ('New York', 45, 50, 0.25, '1994-11-27 12:34:56');

INSERT INTO postgres_db.weather (city, temp_lo, temp_hi, prcp, date) 
	VALUES('San Francisco', 43, 57, 0.0, '1994-11-29 12:34:56');
    
INSERT INTO postgres_db.weather (city, temp_lo, temp_hi, prcp, date) 
	VALUES('San Francisco', 39, 57, 0.0, '1994-11-29 12:34:56');
    
INSERT INTO postgres_db.weather (date, city, temp_hi, temp_lo) 
	VALUES ('1994-11-29 12:34:56', 'Hayward', 54, 37);
    
INSERT INTO postgres_db.cities VALUES ('San Francisco',1,1);

INSERT INTO postgres_db.cities VALUES ('New York',2,2);

-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:San Francisco,46,50,0.25,19941127120000
-- RESULT:New York,45,50,0.25,19941127120000
-- RESULT:San Francisco,43,57,0,19941129120000
-- RESULT:San Francisco,39,57,0,19941129120000
-- RESULT:Hayward,37,54,null,19941129120000
select * from postgres_db.weather;

-- RESULT:name,lat,lon
-- RESULT:San Francisco,1.000,1.000
-- RESULT:New York,2.000,2.000
select * from postgres_db.cities;

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,city,VARCHAR,false,null,false
-- RESULT:1,temp_lo,INTEGER,false,null,false
-- RESULT:2,temp_hi,INTEGER,false,null,false
-- RESULT:3,prcp,FLOAT,false,null,false
-- RESULT:4,date,DATE,false,null,false
PRAGMA table_info('postgres_db.weather');

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,name,VARCHAR,false,null,false
-- RESULT:1,lat,DECIMAL(18,3),false,null,false
-- RESULT:2,lon,DECIMAL(18,3),false,null,false
PRAGMA table_info('postgres_db.cities');

-- RESULT:database,schema,name,column_names,column_types,temporary
-- RESULT:postgres_db,public,cities,[name, lat, lon],[VARCHAR, 'DECIMAL(18,3)', 'DECIMAL(18,3)'],false
-- RESULT:postgres_db,public,weather,[city, temp_lo, temp_hi, prcp, date],[VARCHAR, INTEGER, INTEGER, FLOAT, DATE],false
select * from (SHOW ALL TABLES) order by name;

-- RESULT:schemaname,tablename,tableowner,tablespace,hasindexes,hasrules,hastriggers
-- RESULT:public,cities,duckdb,null,false,false,false
-- RESULT:public,weather,duckdb,null,false,false,false
SELECT * FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema' order by tablename;

.print ********************************************************
.print you can copy tables directly from postgresql to duckdb
.print ********************************************************
CREATE OR REPLACE TABLE weather AS FROM postgres_db.weather;
CREATE OR REPLACE TABLE cities AS FROM postgres_db.cities;

.print ********************************************************
.print you can copy tables directly from duckdb to postgresql
.print ********************************************************
CREATE OR REPLACE TABLE postgres_db.new_weather AS FROM weather;
CREATE OR REPLACE TABLE postgres_db.new_cities AS FROM cities;

-- RESULT:database,schema,name,column_names,column_types,temporary
-- RESULT:postgres_db,public,cities,[name, lat, lon],[VARCHAR, 'DECIMAL(18,3)', 'DECIMAL(18,3)'],false
-- RESULT:postgres_db,public,new_cities,[name, lat, lon],[VARCHAR, 'DECIMAL(18,3)', 'DECIMAL(18,3)'],false
-- RESULT:postgres_db,public,new_weather,[city, temp_lo, temp_hi, prcp, date],[VARCHAR, INTEGER, INTEGER, FLOAT, DATE],false
-- RESULT:postgres_db,public,weather,[city, temp_lo, temp_hi, prcp, date],[VARCHAR, INTEGER, INTEGER, FLOAT, DATE],false
-- RESULT:test,main,cities,[name, lat, lon],[VARCHAR, 'DECIMAL(18,3)', 'DECIMAL(18,3)'],false
-- RESULT:test,main,weather,[city, temp_lo, temp_hi, prcp, date],[VARCHAR, INTEGER, INTEGER, FLOAT, DATE],false
select * from (SHOW ALL TABLES) order by database,schema,name;

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:city,VARCHAR,YES,null,null,null
-- RESULT:temp_lo,INTEGER,YES,null,null,null
-- RESULT:temp_hi,INTEGER,YES,null,null,null
-- RESULT:prcp,FLOAT,YES,null,null,null
-- RESULT:date,DATE,YES,null,null,null
DESCRIBE postgres_db.weather;
-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:city,VARCHAR,YES,null,null,null
-- RESULT:temp_lo,INTEGER,YES,null,null,null
-- RESULT:temp_hi,INTEGER,YES,null,null,null
-- RESULT:prcp,FLOAT,YES,null,null,null
-- RESULT:date,DATE,YES,null,null,null
DESCRIBE weather;
-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:city,VARCHAR,YES,null,null,null
-- RESULT:temp_lo,INTEGER,YES,null,null,null
-- RESULT:temp_hi,INTEGER,YES,null,null,null
-- RESULT:prcp,FLOAT,YES,null,null,null
-- RESULT:date,DATE,YES,null,null,null
DESCRIBE postgres_db.new_weather;

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:name,VARCHAR,YES,null,null,null
-- RESULT:lat,DECIMAL(18,3),YES,null,null,null
-- RESULT:lon,DECIMAL(18,3),YES,null,null,null
DESCRIBE postgres_db.cities;
-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:name,VARCHAR,YES,null,null,null
-- RESULT:lat,DECIMAL(18,3),YES,null,null,null
-- RESULT:lon,DECIMAL(18,3),YES,null,null,null
DESCRIBE cities;
-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:name,VARCHAR,YES,null,null,null
-- RESULT:lat,DECIMAL(18,3),YES,null,null,null
-- RESULT:lon,DECIMAL(18,3),YES,null,null,null
DESCRIBE postgres_db.new_cities;

-- RESULT:name,lat,lon
-- RESULT:San Francisco,1.000,1.000
-- RESULT:New York,2.000,2.000
select * from postgres_db.cities;

-- RESULT:name,lat,lon
-- RESULT:San Francisco,1.000,1.000
-- RESULT:New York,2.000,2.000
select * from postgres_db.new_cities;

-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:San Francisco,46,50,0.25,19941127120000
-- RESULT:New York,45,50,0.25,19941127120000
-- RESULT:San Francisco,43,57,0,19941129120000
-- RESULT:San Francisco,39,57,0,19941129120000
-- RESULT:Hayward,37,54,null,19941129120000
select * from postgres_db.weather;

-- RESULT:city,temp_lo,temp_hi,prcp,date
-- RESULT:San Francisco,46,50,0.25,19941127120000
-- RESULT:New York,45,50,0.25,19941127120000
-- RESULT:San Francisco,43,57,0,19941129120000
-- RESULT:San Francisco,39,57,0,19941129120000
-- RESULT:Hayward,37,54,null,19941129120000
select * from postgres_db.new_weather;

-- dropping the public schema with CASCADE deletes all of the associated tables too
DROP SCHEMA postgres_db.public CASCADE;

-- recreate the public schema
CREATE SCHEMA postgres_db.public;

select * from (SHOW ALL TABLES) order by name;

DETACH postgres_db;
