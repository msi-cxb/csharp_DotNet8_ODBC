-- .echo on
-- .timer on
.conn duckdb

drop table if exists company;

CREATE TABLE COMPANY(
	ID             INT			NOT NULL     PRIMARY KEY,
	NAME           TEXT			NOT NULL,
	AGE            INT			NOT NULL,
	ADDRESS        CHAR(50),
	SALARY         REAL
);

INSERT INTO COMPANY(ID, NAME, AGE, ADDRESS, SALARY)
	VALUES
		(1, 'Paul', 32, 'California', 20000.00),
		(2, 'Allen', 25, 'Texas', 15000.00),
		(3, 'Teddy', 23, 'Norway', 20000.00),
		(4, 'Mark', 25, 'Rich-Mond ', 65000.00),
		(5, 'David', 27, 'Texas', 85000.00),
		(6, 'Kim', 22, 'South-Hall', 45000.00);

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,ID,INTEGER,true,null,true
-- RESULT:1,NAME,VARCHAR,true,null,false
-- RESULT:2,AGE,INTEGER,true,null,false
-- RESULT:3,ADDRESS,VARCHAR,false,null,false
-- RESULT:4,SALARY,FLOAT,false,null,false
PRAGMA table_info('company');

-- RESULT:table_name
-- RESULT:COMPANY
WITH AllTables AS (
    SELECT
        table_name
    FROM
        duckdb_tables
),
Tables AS (
    SELECT
        *
    FROM
        AllTables
)
select * from Tables;
