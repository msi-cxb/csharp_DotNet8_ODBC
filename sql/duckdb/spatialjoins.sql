-- https://duckdb.org/2025/08/08/spatial-joins.html

-- .echo on
-- .timer on
.conn duckdb


INSTALL spatial;
LOAD spatial;

.print DuckDB version string
-- RESULT:library_version,source_id,codename
-- RESULT:v1.3.2,0b83e5d2f6,Ossivalis
PRAGMA version;

-- "H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data\spatial\spatialjoins\biketrips.duckdb"
ATTACH '[[__DATAFOLDER__]]\spatial\spatialjoins\biketrips.duckdb' AS biketrips;
-- ATTACH 'H:\csharp_DotNet8_ODBC\bin\Debug\net8.0\data\spatial\spatialjoins\biketrips.duckdb' AS biketrips;

COPY FROM DATABASE biketrips TO test;

DETACH biketrips;

SHOW ALL TABLES;

-- PRAGMA explain_output = 'physical_only';
-- PRAGMA explain_output = 'optimized_only';
SET explain_output = 'all';

-- SET enable_profiling = 'query_tree';
SET enable_profiling = 'no_output';
-- SET enable_profiling = 'json';
-- SET enable_profiling = 'query_tree_optimizer';

-- SET profiling_mode = 'standard';
SET profiling_mode = 'detailed';

-- PRAGMA enable_profile;

SET profiling_output='';

-- This query joins the 58,033,724 rides with the 310 neighborhood polygons
SELECT neighborhood, count(*) AS num_rides
FROM rides
JOIN hoods ON ST_Intersects(rides.start_geom, hoods.geom)
GROUP BY neighborhood
ORDER BY num_rides DESC
LIMIT 3;

-- SELECT neighborhood, count(*) AS num_rides
-- FROM rides
-- JOIN hoods ON ST_DWithin(rides.start_geom, hoods.geom, 0)
-- GROUP BY neighborhood
-- ORDER BY num_rides DESC
-- LIMIT 3;


