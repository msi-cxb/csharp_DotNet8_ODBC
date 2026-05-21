-- https://learndataengineering.com/p/duckdb-for-data-engineers-from-local-to-cloud-with-motherduck

-- note that I added round() and order by to make results reproducible

.echo on
-- .timer on
.conn duckdb

.print DuckDB version string
PRAGMA version;

-- 2_1_reading_a_csv.md

.print ----------------------------------------------------
.print 1. Look at the file structure
DESCRIBE SELECT * 
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv');

.print ----------------------------------------------------
.print 2. Peek at the Data

-- RESULT:Unique Key,Created Date,Closed Date,Agency,Agency Name,Complaint Type,Descriptor,Location Type,Incident Zip,Incident Address,Street Name,Cross Street 1,Cross Street 2,Intersection Street 1,Intersection Street 2,Address Type,City,Landmark,Facility Type,Status,Due Date,Resolution Description,Resolution Action Updated Date,Community Board,BBL,Borough,X Coordinate (State Plane),Y Coordinate (State Plane),Open Data Channel Type,Park Facility Name,Park Borough,Vehicle Type,Taxi Company Borough,Taxi Pick Up Location,Bridge Highway Name,Bridge Highway Direction,Road Ramp,Bridge Highway Segment,Latitude,Longitude,Location
-- RESULT:63582397,20241231092411,20250529120000,DOB,Department of Buildings,Elevator,Elevator - Single Device On Property/No Alternate Service,null,10032,1970 AMSTERDAM AVENUE,AMSTERDAM AVENUE,null,null,null,null,ADDRESS,NEW YORK,null,null,Closed,null,The Department of Buildings investigated this complaint and determined that no further action was necessary.,20250529120000,12 MANHATTAN,1021160033,MANHATTAN,1000372,242869,UNKNOWN,Unspecified,MANHATTAN,null,null,null,null,null,null,null,40.83327996642333,-73.9417403043681,(40.83327996642333, -73.9417403043681)
-- RESULT:63575602,20241231085013,20250102120000,DOB,Department of Buildings,Elevator,Elevator - Single Device On Property/No Alternate Service,null,10453,1615 UNIVERSITY AVENUE,UNIVERSITY AVENUE,null,null,null,null,ADDRESS,BRONX,null,null,Closed,null,The Department of Buildings reviewed this complaint and closed it. If the problem still exists, please call 311 and file a new complaint. If you are outside of New York City, please call (212) NEW-YORK (212-639-9675).,20250102120000,05 BRONX,2028780015,BRONX,1006402,247988,UNKNOWN,Unspecified,BRONX,null,null,null,null,null,null,null,40.84731705833017,-73.91993293617895,(40.84731705833017, -73.91993293617895)
-- RESULT:63582349,20241231083210,20250102120000,DOB,Department of Buildings,Elevator,Elevator - Single Device On Property/No Alternate Service,null,10468,2290 DAVIDSON AVENUE,DAVIDSON AVENUE,null,null,null,null,ADDRESS,BRONX,null,null,Closed,null,The Department of Buildings reviewed this complaint and closed it. If the problem still exists, please call 311 and file a new complaint. If you are outside of New York City, please call (212) NEW-YORK (212-639-9675).,20250102120000,07 BRONX,2031970023,BRONX,1010639,252289,UNKNOWN,Unspecified,BRONX,null,null,null,null,null,null,null,40.85911037097102,-73.9046016370002,(40.85911037097102, -73.9046016370002)
-- RESULT:63575549,20241231081406,20250107120000,DOB,Department of Buildings,Elevator,Elevator - Single Device On Property/No Alternate Service,null,10453,2240 WALTON AVENUE,WALTON AVENUE,null,null,null,null,ADDRESS,BRONX,null,null,Closed,null,The Department of Buildings investigated this complaint and issued an Office of Administrative Trials and Hearings (OATH) summons.,20250107120000,05 BRONX,2031820004,BRONX,1010976,251658,UNKNOWN,Unspecified,BRONX,null,null,null,null,null,null,null,40.85737745245203,-73.90338587172995,(40.85737745245203, -73.90338587172995)
-- RESULT:63576030,20241231080055,20250111075909,HPD,Department of Housing Preservation and Development,ELEVATOR,MAINTENANCE,RESIDENTIAL BUILDING,10032,1970 AMSTERDAM AVENUE,AMSTERDAM AVENUE,null,null,null,null,ADDRESS,NEW YORK,null,null,Closed,null,HPD conducted an inspection of this complaint. The conditions observed by the inspector did not violate the housing laws enforced by HPD. The complaint has been closed.,20250111120000,12 MANHATTAN,1021160033,MANHATTAN,1000372,242869,PHONE,Unspecified,MANHATTAN,null,null,null,null,null,null,null,40.83327996642333,-73.9417403043681,(40.83327996642333, -73.9417403043681)
SELECT * 
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv') 
LIMIT 5;

.print ----------------------------------------------------
.print 3. Time Breakdown of Elevator Complaints (Monthly)

-- RESULT:month,complaints
-- RESULT:2024-01,1971
-- RESULT:2024-02,1502
-- RESULT:2024-03,1515
-- RESULT:2024-04,1660
-- RESULT:2024-05,1778
-- RESULT:2024-06,2021
-- RESULT:2024-07,2432
-- RESULT:2024-08,2319
-- RESULT:2024-09,1764
-- RESULT:2024-10,1819
-- RESULT:2024-11,1808
-- RESULT:2024-12,1915
SELECT strftime('%Y-%m', "Created Date") AS month,
       COUNT(*) AS complaints
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv')
GROUP BY month
ORDER BY month;

.print ----------------------------------------------------
.print 4. Geographic Breakdown (by Borough)

-- RESULT:Borough,complaints
-- RESULT:BRONX,9339
-- RESULT:BROOKLYN,5052
-- RESULT:MANHATTAN,4989
-- RESULT:QUEENS,2916
-- RESULT:STATEN ISLAND,208
SELECT "Borough", COUNT(*) AS complaints
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv')
GROUP BY "Borough"
ORDER BY complaints DESC;

.print ----------------------------------------------------
.print 5. Focus on Manhattan Complaints Over Time

-- RESULT:month,complaints
-- RESULT:2024-01,343
-- RESULT:2024-02,327
-- RESULT:2024-03,392
-- RESULT:2024-04,411
-- RESULT:2024-05,455
-- RESULT:2024-06,437
-- RESULT:2024-07,513
-- RESULT:2024-08,473
-- RESULT:2024-09,413
-- RESULT:2024-10,393
-- RESULT:2024-11,415
-- RESULT:2024-12,417
SELECT 
    strftime('%Y-%m', "Created Date") AS month,
    COUNT(*) AS complaints
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv')
WHERE "Borough" = 'MANHATTAN'
GROUP BY month
ORDER BY month;

.print ----------------------------------------------------
.print 6. Elevator Complaints per ZIP (Manhattan Only)

-- RESULT:Incident Zip,complaints
-- RESULT:10031,426
-- RESULT:10032,374
-- RESULT:10025,350
-- RESULT:10039,311
-- RESULT:10030,290
-- RESULT:10027,285
-- RESULT:10033,236
-- RESULT:10026,219
-- RESULT:10040,199
-- RESULT:10029,180
-- RESULT:10036,180
-- RESULT:10035,152
-- RESULT:10019,146
-- RESULT:10016,121
-- RESULT:10037,120
-- RESULT:10002,108
-- RESULT:10001,103
-- RESULT:10023,101
-- RESULT:10024,100
-- RESULT:10003,89
-- RESULT:10009,88
-- RESULT:10028,75
-- RESULT:10034,67
-- RESULT:10022,64
-- RESULT:10011,62
-- RESULT:10128,54
-- RESULT:10010,53
-- RESULT:10006,45
-- RESULT:10021,39
-- RESULT:10038,39
-- RESULT:10065,36
-- RESULT:10017,34
-- RESULT:10018,30
-- RESULT:10075,30
-- RESULT:10013,28
-- RESULT:10012,27
-- RESULT:10463,23
-- RESULT:10005,22
-- RESULT:10014,18
-- RESULT:10007,17
-- RESULT:10280,14
-- RESULT:10069,11
-- RESULT:10044,5
-- RESULT:10282,4
-- RESULT:null,4
-- RESULT:10004,3
-- RESULT:10020,1
-- RESULT:10055,1
-- RESULT:10112,1
-- RESULT:10118,1
-- RESULT:10179,1
-- RESULT:10278,1
-- RESULT:10281,1
SELECT "Incident Zip",
       COUNT(*) AS complaints
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv')
WHERE "Borough" = 'MANHATTAN'
GROUP BY "Incident Zip"
ORDER BY complaints DESC, "Incident Zip";

.print ----------------------------------------------------
.print 7. Elevator Complaints by Street Name (Top 20 in Manhattan)

-- RESULT:Street Name,complaints
-- RESULT:ST NICHOLAS AVENUE,163
-- RESULT:BROADWAY,138
-- RESULT:7 AVENUE,89
-- RESULT:RIVERSIDE DRIVE,81
-- RESULT:FORT WASHINGTON AVENUE,68
-- RESULT:WEST  141 STREET,68
-- RESULT:AMSTERDAM AVENUE,66
-- RESULT:WEST  145 STREET,63
-- RESULT:LEXINGTON AVENUE,62
-- RESULT:SAINT NICHOLAS AVENUE,58
-- RESULT:WEST   87 STREET,55
-- RESULT:WEST  150 STREET,50
-- RESULT:10 AVENUE,47
-- RESULT:WEST  110 STREET,47
-- RESULT:5 AVENUE,46
-- RESULT:PARK AVENUE,46
-- RESULT:SOUTH PINEHURST AVENUE,46
-- RESULT:WEST   46 STREET,45
-- RESULT:WEST  136 STREET,45
-- RESULT:WEST  118 STREET,42
SELECT "Street Name",
       COUNT(*) AS complaints
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv')
WHERE "Borough" = 'MANHATTAN'
GROUP BY "Street Name"
ORDER BY complaints DESC, "Street Name" 
LIMIT 20;

.print ----------------------------------------------------
.print Finding the Optimal HQ Location

.print ----------------------------------------------------
.print 8. Simple Centroid Approach

-- RESULT:hq_lat,hq_lon
-- RESULT:40.796585257376,-73.958518843133
SELECT 
      round(AVG("Latitude"),12) AS hq_lat,
      round(AVG("Longitude"),12) AS hq_lon,
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv')
WHERE "Borough" = 'MANHATTAN';

.print ----------------------------------------------------
.print 8_1. Weighted Centroid (Better)

-- RESULT:hq_lat,hq_lon
-- RESULT:40.772045910104,-73.914052054985
WITH street_points AS (
  SELECT 
      "Street Name",
      AVG("Latitude") AS lat,
      AVG("Longitude") AS lon,
      COUNT(*) AS complaints
  FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv')
  WHERE "Borough" = 'MANHATTAN'
  GROUP BY "Street Name"
)
SELECT 
    ROUND(SUM(lat * complaints) / SUM(complaints),12) AS hq_lat,
    ROUND(SUM(lon * complaints) / SUM(complaints),12) AS hq_lon
FROM street_points;

.print ----------------------------------------------------
.print 8_2. Median Point (Robust to Outliers)

-- RESULT:median_lat,median_lon
-- RESULT:40.802611904219,-73.951262259324
SELECT 
    ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY "Latitude"),12) AS median_lat,
    ROUND(percentile_cont(0.5) WITHIN GROUP (ORDER BY "Longitude"),12) AS median_lon
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv')
WHERE "Borough" = 'MANHATTAN';

-- 2_4_saving_and_reusing_local_databases.md

.print ----------------------------------------------------
.print create a persistent table from your CSV
CREATE TABLE elevator_requests AS
SELECT *
FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv', HEADER=true, AUTO_DETECT=true);

.print ----------------------------------------------------
.print should list elevator_requests
SHOW TABLES;

.print ----------------------------------------------------
.print quick sanity checks
-- RESULT:count_star()
-- RESULT:22504
SELECT COUNT(*) FROM elevator_requests;

-- RESULT:count_star()
-- RESULT:22504
SELECT COUNT(*) FROM read_csv_auto('[[__DATAFOLDER__]]\311_Elevator_Service_Requests_.csv', HEADER=true, AUTO_DETECT=true);


.print ----------------------------------------------------
.print run a query
SELECT 
    strftime('%Y-%m', "Created Date") AS month,
    COUNT(*) AS complaints
FROM elevator_requests
WHERE "Borough" = 'MANHATTAN'
GROUP BY month
ORDER BY month;

.print ----------------------------------------------------
.print should list elevator_requests
SHOW TABLES;

.print ----------------------------------------------------
.print sample rows
SELECT * FROM elevator_requests LIMIT 5;

.print ----------------------------------------------------
.print The EXPLAIN statement displays the physical plan, i.e., the query plan that will get executed
.print due to embedded carriage return/line feed, cannot verify result
EXPLAIN 
SELECT 
    strftime('%Y', "created date") AS year,
    COUNT(*) AS complaints
FROM elevator_requests
GROUP BY year
ORDER BY year;

.print ----------------------------------------------------
.print EXPLAIN ANALYZE both pretty-prints the query plan, 
.print and executes it, providing run-time performance numbers 
.print for every operator, as well as the estimated cardinality (EC) 
.print and the actual cardinality.
.print due to embedded carriage return/line feed, cannot verify result
.print also note strftime is not efficient
EXPLAIN ANALYZE
SELECT 
    strftime('%Y', "created date") AS year,
    COUNT(*) AS complaints
FROM elevator_requests
GROUP BY year
ORDER BY year;

.print EXTRACT is more efficient
EXPLAIN ANALYZE
SELECT
  EXTRACT(YEAR FROM "created date") AS year,
  COUNT(*) AS complaints
FROM elevator_requests
GROUP BY year
ORDER BY year;
