.echo ON
.timer ON

-- 90 days of 10 Hz data --> ????? records

.print create the big table
CREATE OR REPLACE TABLE big_csv_2 (
    ID BIGINT,
    y BIGINT,
    hash VARCHAR,
    DueDate DATETIME,
    year INT64,
    month INT64,
    day INT64
);

.print populate the big table, include year/month/data for partitioning later
INSERT INTO big_csv_2
    SELECT
        i as ID,
        i as y, 
        md5(CAST(i as STRING)) as hash, 
        epoch_ms( cast(1640995200000+(i*100) as BIGINT) ) as DueDate,
        strftime(DueDate, '%Y') as year, 
        strftime(DueDate, '%m') as month, 
        strftime(DueDate, '%d') as day
    from
        generate_series(1, 90*86400*10) s(i);

.print do calcs on the big table
-- RESULT:cnt,avg,mindate,maxdate,microseconds
-- RESULT:77760000,38880000.5,2022/01/01 - 00:00:00.100,2022/04/01 - 00:00:00.000,7775999900000
SELECT 
    count(1) as cnt, 
    avg(ID) as avg, 
    strftime(min(DueDate), '%Y/%m/%d - %H:%M:%S.%g') as mindate, 
    strftime(max(DueDate), '%Y/%m/%d - %H:%M:%S.%g') as maxdate,
    datediff('microseconds',min(DueDate),max(DueDate)) as microseconds
FROM
    big_csv_2;

.print write out table as one big csv
COPY (
    select * from big_csv_2
) TO '[[__DATAFOLDER__]]\big_csv_2.csv' (HEADER, DELIMITER ',');

.print do calcs on the one big csv
-- RESULT:cnt,avg,mindate,maxdate,microseconds
-- RESULT:77760000,38880000.5,2022/01/01 - 00:00:00.100,2022/04/01 - 00:00:00.000,7775999900000
SELECT 
    count(1) as cnt, 
    avg(ID) as avg, 
    strftime(min(DueDate), '%Y/%m/%d - %H:%M:%S.%g') as mindate, 
    strftime(max(DueDate), '%Y/%m/%d - %H:%M:%S.%g') as maxdate,
    datediff('microseconds',min(DueDate),max(DueDate)) as microseconds
FROM 
    '[[__DATAFOLDER__]]\big_csv_2.csv';

.print write data to partitions by year, month, day
COPY big_csv_2 TO '[[__DATAFOLDER__]]\big_csv_2'
(FORMAT csv, PARTITION_BY (year, month, day), OVERWRITE_OR_IGNORE);

.print do calcs on all the partitioned data
-- RESULT:cnt,avg,mindate,maxdate,microseconds
-- RESULT:77760000,38880000.5,2022/01/01 - 00:00:00.100,2022/04/01 - 00:00:00.000,7775999900000
SELECT 
    count(1) as cnt, 
    avg(ID) as avg, 
    strftime(min(DueDate), '%Y/%m/%d - %H:%M:%S.%g') as mindate, 
    strftime(max(DueDate), '%Y/%m/%d - %H:%M:%S.%g') as maxdate,
    datediff('microseconds',min(DueDate),max(DueDate)) as microseconds
FROM 
    '[[__DATAFOLDER__]]\big_csv_2\*\*\*\*.csv';

.print do calcs but only look at february partition
-- RESULT:cnt,avg,mindate,maxdate,microseconds
-- RESULT:24192000,38879999.5,2022/02/01 - 00:00:00.000,2022/02/28 - 23:59:59.900,2419199900000
SELECT 
    count(1) as cnt, 
    avg(ID) as avg, 
    strftime(min(DueDate), '%Y/%m/%d - %H:%M:%S.%g') as mindate, 
    strftime(max(DueDate), '%Y/%m/%d - %H:%M:%S.%g') as maxdate,
    datediff('microseconds',min(DueDate),max(DueDate)) as microseconds
FROM 
    '[[__DATAFOLDER__]]\big_csv_2\*\*\*\*.csv'
WHERE
    month = 2;

