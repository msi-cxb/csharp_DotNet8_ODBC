.echo on
.timer on
.conn duckdb

-- SET explain_output = 'physical_only';
-- SET explain_output = 'optimized_only';
SET explain_output = 'all';

-- SET enable_profiling = 'no_output';
-- SET enable_profiling = 'json';
SET enable_profiling = 'query_tree';
-- SET enable_profiling = 'query_tree_optimizer';

-- SET profiling_mode = 'standard';
-- SET profiling_mode = 'detailed';

SELECT * FROM duckdb_settings() order by name;

CREATE OR REPLACE TABLE students (name VARCHAR, sid INTEGER);
CREATE OR REPLACE TABLE exams (eid INTEGER, subject VARCHAR, sid INTEGER);
INSERT INTO students VALUES ('Mark', 1), ('Joe', 2), ('Matthew', 3);
INSERT INTO exams VALUES (10, 'Physics', 1), (20, 'Chemistry', 2), (30, 'Literature', 3);

EXPLAIN
    SELECT name
    FROM students
    JOIN exams USING (sid)
    WHERE name LIKE 'Ma%';

-- RESULT:name
-- RESULT:Mark
-- RESULT:Matthew
SELECT name
FROM students
JOIN exams USING (sid)
WHERE name LIKE 'Ma%';