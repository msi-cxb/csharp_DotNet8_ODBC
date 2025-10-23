-- .echo on
-- .timer on
.conn duckdb

.print DuckDB version string
-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.1,b390a7c376,Andium
PRAGMA version;
