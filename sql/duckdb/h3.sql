-- https://duckdb.org/2024/07/05/community-extensions.html

-- .echo on
-- .timer on
.conn duckdb

-- this works from duckdb.exe, but not from ODBC
-- my guess is that this is because there is not a version 
-- available that matches git tag
-- need to build/install driver based on release tag and not developer commit

INSTALL h3 FROM community;
LOAD h3;

-- RESULT: cell_id,boundary,cnt617733150970216447,POLYGON ((-73.997008 40.764602, -73.999112 40.763663, -73.999042 40.761902, -73.996869 40.761080, -73.994765 40.762018, -73.994834 40.763779, -73.997008 40.764602)),24406
SELECT
    h3_latlng_to_cell(pickup_latitude, pickup_longitude, 9) AS cell_id,
    h3_cell_to_boundary_wkt(cell_id) AS boundary,
    count() AS cnt
FROM read_parquet('https://blobs.duckdb.org/data/yellow_tripdata_2010-01.parquet')
GROUP BY cell_id
HAVING cnt > 10
limit 1;

