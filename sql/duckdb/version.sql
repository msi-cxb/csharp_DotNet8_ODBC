.echo on
.timer on

.print DuckDB version string
-- RESULT:library_version,source_id
-- RESULT:v1.3.0-dev3365,fda0ba6a7a
PRAGMA version;
