-- https://duckdb.org/2025/09/17/ducklake-03.html

.echo on
.timer on
.conn duckdb

INSTALL ducklake;
LOAD ducklake;

INSTALL spatial;
LOAD spatial;

ATTACH 'ducklake:my_ducklake.ducklake' AS ducklake;
CREATE TABLE geometry_table (polygons GEOMETRY);
INSERT INTO geometry_table VALUES ('POLYGON((0 0, 0 1, 1 1, 1 0, 0 0))');

-- ODBC can't represent/display binary GEOMETRY type for polygons column
-- However, using ST_AsText() solves that problem
-- RESULT:st_astext(polygons),area
-- RESULT:POLYGON ((0 0, 0 1, 1 1, 1 0, 0 0)),1
SELECT
    ST_AsText(polygons),
    ST_Area(polygons) AS area
FROM geometry_table;


