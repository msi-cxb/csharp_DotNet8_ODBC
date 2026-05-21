.echo on
-- .timer on
.conn duckdb

PRAGMA version;

CREATE OR REPLACE TABLE test AS
    SELECT *
    FROM (VALUES (1, 2), (3, 4)) AS t(a, b);

-- RESULT:name,file
-- RESULT:test,test.duckdb
SELECT name, regexp_replace(file, '^.*[\\/]', '', 'g') as file
FROM pragma_database_list
WHERE file IS NOT NULL;


-- RESULT:name
-- RESULT:test
PRAGMA show_tables;

-- RESULT:database,schema,name,column_names,column_types,temporary
-- RESULT:test,main,test,[a, b],[INTEGER, INTEGER],false
PRAGMA show_tables_expanded;

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,a,INTEGER,false,null,false
-- RESULT:1,b,INTEGER,false,null,false
PRAGMA table_info('test');

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,a,INTEGER,false,null,false
-- RESULT:1,b,INTEGER,false,null,false
CALL pragma_table_info('test');



