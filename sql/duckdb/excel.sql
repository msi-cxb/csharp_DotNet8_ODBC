.timer on
.echo on

.print duckdb excel
-- As of DuckDB 1.2 also provides functionality to read and write Excel (.xlsx) files.

INSTALL excel;
LOAD excel;

-- excel scalar functions

-- RESULT:timestamp
-- RESULT:9:31 PM
SELECT excel_text(1_234_567.897, 'h:mm AM/PM') AS timestamp;

-- RESULT:timestamp
-- RESULT:9 PM
SELECT excel_text(1_234_567.897, 'h AM/PM') AS timestamp;

CREATE OR REPLACE TABLE test AS
    SELECT *
    FROM (VALUES (1, 2), (3, 4)) AS t(a, b);

COPY test TO '[[__DATAFOLDER__]]\test.xlsx' WITH (FORMAT xlsx, HEADER true);

-- TIMER: 13 milliseconds
-- RESULT:a,b
-- RESULT:1,2
-- RESULT:3,4
SELECT * FROM '[[__DATAFOLDER__]]\test.xlsx';

-- RESULT:a,b
-- RESULT:1,2
-- RESULT:3,4
SELECT * FROM read_xlsx('[[__DATAFOLDER__]]\test.xlsx', header = true);

CREATE OR REPLACE TABLE test (a DOUBLE, b DOUBLE);

COPY test FROM '[[__DATAFOLDER__]]\test.xlsx' WITH (FORMAT xlsx, HEADER);

-- RESULT:a,b
-- RESULT:1,2
-- RESULT:3,4
SELECT * FROM test;


