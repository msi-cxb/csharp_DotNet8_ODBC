.echo on
-- .timer on
.conn duckdb

-- https://duckdb.org/docs/stable/sql/query_syntax/prepared_statements
CREATE TABLE person (name VARCHAR, age BIGINT);
INSERT INTO person VALUES ('Alice', 37), ('Ana', 35), ('Bob', 41), ('Bea', 25);

PREPARE query_person AS
    SELECT *
    FROM person
    WHERE starts_with(name, ?)
      AND age >= ?;


-- RESULT:name,age
-- RESULT:Bob,41
EXECUTE query_person('B', 40);

