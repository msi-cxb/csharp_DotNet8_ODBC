-- https://duckdb.org/2023/04/28/spatial.html
-- https://downgit.github.io/#/home?url=https:%2F%2Fgithub.com%2Fduckdb%2Fduckdb-spatial%2Ftree%2Fmain%2Ftest%2Fdata

.echo on
.timer on

INSTALL spatial;
LOAD spatial;

CREATE OR REPLACE TABLE rides AS
    SELECT * 
    FROM '.\data\spatial\nyc_taxi\yellow_tripdata_2010-01-limit1mil.parquet';
    
-- RESULT:vendor_id,pickup_datetime,dropoff_datetime,passenger_count,trip_distance,pickup_longitude,pickup_latitude,rate_code,store_and_fwd_flag,dropoff_longitude,dropoff_latitude,payment_type,fare_amount,surcharge,mta_tax,tip_amount,tolls_amount,total_amount
-- RESULT:VTS,2010-01-01 00:00:17,2010-01-01 00:00:17,3,0,-73.87105699999998,40.773522,1,null,-73.871048,40.773545,CAS,45,0,0.5,0,0,45.5
select * from rides limit 1;

-- Load the NYC taxi zone data from a shapefile using the gdal-based ST_Read function
CREATE OR REPLACE TABLE zones AS
    SELECT zone, LocationId, borough, geom 
    FROM ST_Read('.\data\spatial\nyc_taxi\taxi_zones\taxi_zones.shx');

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,zone,VARCHAR,false,null,false
-- RESULT:1,LocationID,INTEGER,false,null,false
-- RESULT:2,borough,VARCHAR,false,null,false
-- RESULT:3,geom,GEOMETRY,false,null,false
PRAGMA table_info('zones');

CREATE OR REPLACE TABLE cleaned_rides AS
    SELECT 
        ST_Point(pickup_latitude, pickup_longitude) AS pickup_point,
        ST_Point(dropoff_latitude, dropoff_longitude) AS dropoff_point,
        dropoff_datetime::TIMESTAMP - pickup_datetime::TIMESTAMP AS time,
        trip_distance,
        ST_Distance(
            ST_Transform(pickup_point, 'EPSG:4326', 'ESRI:102718'), 
            ST_Transform(dropoff_point, 'EPSG:4326', 'ESRI:102718')) / 5280 
            AS aerial_distance, 
        trip_distance - aerial_distance AS diff 
    FROM rides 
    WHERE diff > 0
    ORDER BY diff DESC;

DELETE FROM cleaned_rides WHERE rowid > 5000;

CREATE OR REPLACE TABLE joined AS 
    SELECT 
        pickup_point,
        dropoff_point,
        start_zone.zone AS start_zone,
        end_zone.zone AS end_zone, 
        trip_distance,
        time,
    FROM cleaned_rides 
    JOIN zones AS start_zone 
      ON ST_Within(ST_Transform(pickup_point, 'EPSG:4326', 'ESRI:102718'), start_zone.geom) 
    JOIN zones AS end_zone 
      ON ST_Within(ST_Transform(dropoff_point, 'EPSG:4326', 'ESRI:102718'), end_zone.geom);

COPY (
    SELECT 
        ST_MakeLine(pickup_point, dropoff_point)
            .ST_FlipCoordinates()
            .ST_AsWKB()
            AS wkb_geometry,
        start_zone,
        end_zone,
        time::VARCHAR AS trip_time 
    FROM joined
    order by trip_time
    limit 10
) TO '.\data\joined.geojsonseq' 
WITH ( 
    FORMAT gdal, 
    DRIVER 'GeoJSONSeq',
    LAYER_CREATION_OPTIONS 'WRITE_BBOX=YES',
    OVERWRITE_OR_IGNORE
);

-- RESULT:type,properties,geometry
-- RESULT:Feature,{'start_zone': West Chelsea/Hudson Yards, 'end_zone': East Chelsea, 'trip_time': '-00:26:00'},{'type': LineString, 'coordinates': [[-74.001618, 40.751218], [-74.000518, 40.747762]]}
-- RESULT:Feature,{'start_zone': West Village, 'end_zone': Penn Station/Madison Sq West, 'trip_time': '00:00:00'},{'type': LineString, 'coordinates': [[-74.006225, 40.733842], [-73.994488, 40.750753]]}
-- RESULT:Feature,{'start_zone': Midtown South, 'end_zone': Midtown South, 'trip_time': '00:00:00'},{'type': LineString, 'coordinates': [[-73.985487, 40.744157], [-73.985487, 40.744157]]}
-- RESULT:Feature,{'start_zone': Lincoln Square East, 'end_zone': Garment District, 'trip_time': '00:00:00'},{'type': LineString, 'coordinates': [[-73.982077, 40.76935], [-73.99128, 40.753808]]}
-- RESULT:Feature,{'start_zone': Lincoln Square East, 'end_zone': Upper East Side North, 'trip_time': '00:00:00'},{'type': LineString, 'coordinates': [[-73.9831, 40.773422], [-73.961973, 40.776448]]}
-- RESULT:Feature,{'start_zone': Midtown East, 'end_zone': West Chelsea/Hudson Yards, 'trip_time': '00:00:00'},{'type': LineString, 'coordinates': [[-73.977277, 40.753418], [-74.007698, 40.742945]]}
-- RESULT:Feature,{'start_zone': Yorkville East, 'end_zone': Flatiron, 'trip_time': '00:00:00'},{'type': LineString, 'coordinates': [[-73.94417, 40.779758], [-73.998145, 40.73963]]}
-- RESULT:Feature,{'start_zone': Sunnyside, 'end_zone': Sunnyside, 'trip_time': '00:00:00'},{'type': LineString, 'coordinates': [[-73.926423, 40.745591], [-73.926423, 40.745591]]}
-- RESULT:Feature,{'start_zone': West Village, 'end_zone': West Village, 'trip_time': '00:00:00'},{'type': LineString, 'coordinates': [[-74.006248, 40.733819], [-74.006249, 40.733826]]}
-- RESULT:Feature,{'start_zone': Little Italy/NoLiTa, 'end_zone': Flatiron, 'trip_time': '00:00:00'},{'type': LineString, 'coordinates': [[-73.994627, 40.719088], [-73.99459, 40.745243]]}
SELECT *
FROM read_json('.\data\joined.geojsonseq');