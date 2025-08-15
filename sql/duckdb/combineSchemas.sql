.echo on
.timer on

PRAGMA version;

-- RESULT:current_setting('threads')
-- RESULT:6
SELECT current_setting('threads');

-- remove data.parquet to start fresh
.system del /Q [[__DATAFOLDER__]]\flights*.csv > nul 2>&1
-- .system del /Q [[__DATAFOLDER__]]\large_table_sqlite.parquet > nul 2>&1

-- .quit

-- get the sample data from https://duckdb.org/data/flights.csv
CREATE OR REPLACE TABLE flights AS FROM 'https://duckdb.org/data/flights.csv';

-- below is based on https://duckdb.org/docs/stable/data/multiple_files/combining_schemas

-- RESULT:column_name,column_type,null,key,default,extra
-- RESULT:FlightDate,DATE,YES,null,null,null
-- RESULT:UniqueCarrier,VARCHAR,YES,null,null,null
-- RESULT:OriginCityName,VARCHAR,YES,null,null,null
-- RESULT:DestCityName,VARCHAR,YES,null,null,null
DESCRIBE flights;

-- RESULT:FlightDate,UniqueCarrier,OriginCityName,DestCityName
-- RESULT:19880101120000,AA,New York, NY,Los Angeles, CA
-- RESULT:19880102120000,AA,New York, NY,Los Angeles, CA
-- RESULT:19880103120000,AA,New York, NY,Los Angeles, CA
SELECT * FROM flights order by FlightDate;

.print *********************************
.print UNION ALL
COPY (SELECT * FROM flights where FlightDate != '1988-01-03') TO './data/flights1.csv' (FORMAT csv, DELIMITER '|', HEADER);
COPY (SELECT * FROM flights where FlightDate = '1988-01-03') TO './data/flights2.csv' (FORMAT csv, DELIMITER '|', HEADER);

-- same schema so this is like a UNION ALL of the flights csv files
-- RESULT:FlightDate,UniqueCarrier,OriginCityName,DestCityName
-- RESULT:19880101120000,AA,New York, NY,Los Angeles, CA
-- RESULT:19880102120000,AA,New York, NY,Los Angeles, CA
-- RESULT:19880103120000,AA,New York, NY,Los Angeles, CA
select * from './data/flights*.csv' order by FlightDate;

.print *********************************
.print UNION BY NAME
COPY (SELECT FlightDate,OriginCityName,DestCityName FROM flights where FlightDate != '1988-01-03') TO './data/flights3.csv' (FORMAT csv, DELIMITER '|', HEADER);
COPY (SELECT * FROM flights where FlightDate = '1988-01-03') TO './data/flights4.csv' (FORMAT csv, DELIMITER '|', HEADER);

-- RESULT:FlightDate,OriginCityName,DestCityName,UniqueCarrier
-- RESULT:19880101120000,New York, NY,Los Angeles, CA,null
-- RESULT:19880102120000,New York, NY,Los Angeles, CA,null
-- RESULT:19880103120000,New York, NY,Los Angeles, CA,AA
SELECT * FROM read_csv(['./data/flights3.csv','./data/flights4.csv'], union_by_name = true) order by FlightDate;
