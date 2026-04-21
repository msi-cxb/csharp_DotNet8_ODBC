.echo on
-- .timer on
.conn duckdb

SET threads TO 1;

-- RESULT:threads
-- RESULT:1
SELECT current_setting('threads') AS threads;
