.echo on
-- .timer on
.conn duckdb

.print DuckDB version string
-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.0,b8a06e4a22,Andium
PRAGMA version;

CREATE OR REPLACE TABLE test AS
    SELECT *
    FROM (VALUES (1, 2), (3, 4)) AS t(a, b);

-- RESULT:seq,name,file
-- RESULT:592,test,g:\csharp_dotnet8_odbc\bin\debug\net8.0\db\test.db
PRAGMA database_list;

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



