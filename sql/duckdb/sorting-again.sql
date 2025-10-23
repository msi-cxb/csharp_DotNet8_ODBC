-- https://duckdb.org/2025/09/24/sorting-again.html

.echo on
.timer on
.conn duckdb

.print DuckDB version string
-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.1,b390a7c376,Andium
PRAGMA version;

SELECT
    s,
    create_sort_key(s, 'asc nulls last') AS k1,
    create_sort_key(s, 'asc nulls first') AS k2
FROM
    (VALUES ('hello'), ('world'), (NULL)) t(s);

.print ********************************** 10m
CREATE OR REPLACE TABLE ascending10m AS
    SELECT range AS i FROM range(10_000_000);

CREATE OR REPLACE TABLE descending10m AS
    SELECT range AS i FROM range(9_999_999, 0, -1);

CREATE OR REPLACE TABLE random10m AS
    SELECT range AS i FROM range(10_000_000) ORDER BY random();

SELECT any_value(i) FROM (FROM ascending10m ORDER BY i);
SELECT any_value(i) FROM (FROM descending10m ORDER BY i);
SELECT any_value(i) FROM (FROM random10m ORDER BY i);

.print ********************************** 100m
CREATE OR REPLACE TABLE ascending100m AS
    SELECT range AS i FROM range(100_000_000);

CREATE OR REPLACE TABLE descending100m AS
    SELECT range AS i FROM range(99_999_999, 0, -1);

CREATE OR REPLACE TABLE random100m AS
    SELECT range AS i FROM range(100_000_000) ORDER BY random();

SELECT any_value(i) FROM (FROM ascending100m ORDER BY i);
SELECT any_value(i) FROM (FROM descending100m ORDER BY i);
SELECT any_value(i) FROM (FROM random100m ORDER BY i);

.print ********************************** 1000m
CREATE OR REPLACE TABLE ascending1000m AS
    SELECT range AS i FROM range(1_000_000_000);

CREATE OR REPLACE TABLE descending1000m AS
    SELECT range AS i FROM range(999_999_999, 0, -1);

CREATE OR REPLACE TABLE random1000m AS
    SELECT range AS i FROM range(1_000_000_000) ORDER BY random();

SELECT any_value(i) FROM (FROM ascending1000m ORDER BY i);
SELECT any_value(i) FROM (FROM descending1000m ORDER BY i);
SELECT any_value(i) FROM (FROM random1000m ORDER BY i);



