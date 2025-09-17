-- https://duckdb.org/2024/07/05/community-extensions.html

-- .echo on
-- .timer on
.conn duckdb

-- this works from duckdb.exe and ODBC with V1.4.0

INSTALL h3 FROM community;
LOAD h3;

-- RESULT:cell_id,boundary,cnt
-- RESULT:619056821840379903,POLYGON ((0.000098 -0.000311, 0.000362 0.001335, -0.000777 0.002232, -0.002182 0.001483, -0.002446 -0.000163, -0.001306 -0.001060, 0.000098 -0.000311)),268965
SELECT
    h3_latlng_to_cell(pickup_latitude, pickup_longitude, 9) AS cell_id,
    h3_cell_to_boundary_wkt(cell_id) AS boundary,
    count() AS cnt
FROM read_parquet('https://blobs.duckdb.org/data/yellow_tripdata_2010-01.parquet')
GROUP BY cell_id
HAVING cnt > 10
order by cnt desc
limit 1;

