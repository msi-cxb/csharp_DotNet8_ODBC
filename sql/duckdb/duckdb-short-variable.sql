.echo on
-- .timer on
.conn duckdb

SET VARIABLE my_var = 30;

-- RESULT:total
-- RESULT:50
SELECT 20 + getvariable('my_var') AS total;

