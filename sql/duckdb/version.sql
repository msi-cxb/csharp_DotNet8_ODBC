.echo on
.timer on

.print DuckDB version string
-- RESULT:library_version,source_id,codename
-- RESULT:v1.3.2,0b83e5d2f6,Ossivalis
PRAGMA version;
