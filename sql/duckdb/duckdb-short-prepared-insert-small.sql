.echo on
-- .timer on
.conn duckdb

.print
.print ********************************************
.print
PRAGMA version;
.print
.print ********************************************
.print

DROP TABLE IF EXISTS big_table;

CREATE OR REPLACE TABLE big_table(id BIGINT, hash VARCHAR, rand DOUBLE, "value" DOUBLE);

PREPARE insert_stmt AS INSERT INTO big_table (id, hash, rand, value) VALUES (?,?,?,?);

-- this error started with version 1.4.1...submitted issue on github waiting for answer.
--  RESULT-ERROR:Prepared statement not a cursor-specification
EXECUTE insert_stmt(1,'704719932875954298',1.0,0.7095996033937675974);

-- RESULT:id,hash,rand,value
-- RESULT:1,704719932875954298,1,0.7095996033937676
SELECT * FROM big_table;

.print
.print ********************************************
.print

-- https://duckdb.org/docs/current/sql/query_syntax/prepared_statements

CREATE TABLE person (name VARCHAR, age BIGINT);
INSERT INTO person VALUES ('Alice', 37), ('Ana', 35), ('Bob', 41), ('Bea', 25);

PREPARE query_person AS
    SELECT *
    FROM person
    WHERE starts_with(name, ?)
      AND age >= ?;

EXECUTE query_person('B', 40);
