-- https://duckdb.org/2025/08/08/spatial-joins.html

.echo on
-- .timer on
.conn duckdb


FORCE INSTALL spatial from '.\extensions\duckdb';
-- INSTALL spatial;
LOAD spatial;

PRAGMA version;

-- https://blobs.duckdb.org/data/biketrips.duckdb
ATTACH '[[__DATAFOLDER__]]\spatial\spatialjoins\biketrips.duckdb' AS biketrips;

COPY FROM DATABASE biketrips TO test;

DETACH biketrips;

-- RESULT:database,schema,name,column_names,column_types,temporary
-- RESULT:test,main,hoods,[neighborhood, geom],[VARCHAR, GEOMETRY],false
-- RESULT:test,main,rides,[bikeid, start_geom],[BIGINT, GEOMETRY],false
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
-- it can take as long as 2 minutes running in odbc, 30 seconds 
-- RESULT:neighborhood,num_rides
-- RESULT:Midtown,6253835
-- RESULT:Chelsea,6238693
-- RESULT:East Village,4047396
SELECT neighborhood, count(*) AS num_rides
FROM rides
JOIN hoods ON ST_Intersects(rides.start_geom, hoods.geom)
GROUP BY neighborhood
ORDER BY num_rides DESC
LIMIT 3;
