.echo on
.timer on

PRAGMA version;

-- RESULT:current_setting('threads')
-- RESULT:6
SELECT current_setting('threads');

-- remove data.parquet to start fresh
.system del /Q [[__DATAFOLDER__]]\flights*.csv > nul 2>&1
-- .system del /Q [[__DATAFOLDER__]]\large_table_sqlite.parquet > nul 2>&1

-- get the sample data from https://duckdb.org/data/flights.csv
CREATE OR REPLACE TABLE flights AS FROM 'https://duckdb.org/data/flights.csv';

-- Hive Partitioning and Partitioned Writes
COPY (
    SELECT 
        *, 
        year(FlightDate) AS year, 
        month(FlightDate) AS month, 
        day(FlightDate) AS day 
    FROM flights
)  TO './data/flights' (PARTITION_BY (year, month, day),OVERWRITE_OR_IGNORE);

-- we now have the following
-- >tree /F /A ./data/flights
-- H:\CSHARP_DOTNET8_ODBC\BIN\DEBUG\NET8.0\DATA\FLIGHTS
-- \---year=1988
    -- \---month=1
        -- +---day=1
        -- |       data_0.csv
        -- |
        -- +---day=3
        -- |       data_0.csv
        -- |
        -- \---day=2
                -- data_0.csv

-- query all partitions
-- RESULT:FlightDate,UniqueCarrier,OriginCityName,DestCityName,day,month,year
-- RESULT:19880101120000,AA,New York, NY,Los Angeles, CA,1,1,1988
-- RESULT:19880102120000,AA,New York, NY,Los Angeles, CA,2,1,1988
-- RESULT:19880103120000,AA,New York, NY,Los Angeles, CA,3,1,1988
select * from './data/flights/*/*/*/*.csv';

-- this will read any csv files in any subfolders contained in data
-- RESULT:FlightDate,UniqueCarrier,OriginCityName,DestCityName,day,month,year
-- RESULT:19880101120000,AA,New York, NY,Los Angeles, CA,1,1,1988
-- RESULT:19880102120000,AA,New York, NY,Los Angeles, CA,2,1,1988
-- RESULT:19880103120000,AA,New York, NY,Los Angeles, CA,3,1,1988
select * from './data/**/*.csv';

-- though not obvious here, with hive_partitioning this query only read the file "...\data\flights\year=1988\month=1\day=2\data_0.csv"
SELECT 
    *
FROM 
    read_csv('./data/flights/*/*/*/*.csv', hive_partitioning = true)
WHERE 
    year = 1988
    AND month = 1
    AND day = 2;


