-- .echo on
-- .timer on
.conn duckdb

.print DuckDB version string
-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.0,b8a06e4a22,Andium
PRAGMA version;
