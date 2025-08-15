-- .echo on
-- .timer on
.conn duckdb

.print build a table of all DuckDB types

CREATE OR REPLACE TABLE types(
    BIGINT_val	    BIGINT,
    INT8_val	    INT8,
    LONG_val	    LONG,
    BLOB_val	    BLOB,
    BYTEA_val	    BYTEA,
    BINARY_val	    BINARY,
    VARBINARY_val	VARBINARY,
    BOOLEAN_val	    BOOLEAN,
    BOOL_val	    BOOL,
    LOGICAL_val	    LOGICAL,
    DATE_val	    DATE,
    DECIMAL_val	    DECIMAL,
    NUMERIC_val	    NUMERIC,
    DOUBLE_val	    DOUBLE,
    FLOAT8_val	    FLOAT8,
    FLOAT_val	    FLOAT,
    FLOAT4_val	    FLOAT4,
    REAL_val	    REAL,
    HUGEINT_val	    HUGEINT,
    INTEGER_val	    INTEGER,
    INT4_val	    INT4,
    INT_val	        INT,
    SIGNED_val	    SIGNED,
    INTERVAL_val	INTERVAL,
    JSON_val	    JSON,
    SMALLINT_val	SMALLINT,
    INT2_val	    INT2,
    SHORT_val	    SHORT,
    TIME_val	    TIME,
    TIMESTAMPTZ_val	TIMESTAMPTZ,
    TIMESTAMP_val	TIMESTAMP,
    DATETIME_val	DATETIME,
    TINYINT_val     TINYINT,
    INT1_val	    INT1,
    UBIGINT_val	    UBIGINT,
    UHUGEINT_val	UHUGEINT,
    UINTEGER_val	UINTEGER,
    USMALLINT_val	USMALLINT,
    UTINYINT_val	UTINYINT,
    UUID_val	    UUID,
    VARCHAR_val	    VARCHAR,
    CHAR_val	    CHAR,
    BPCHAR_val	    BPCHAR,
    TEXT_val	    TEXT,
    STRING_val	    STRING
);

.print insert into the table

INSERT INTO types VALUES (
1,
1,
1,
'123456789abcdef'::BLOB,
'123456789abcdef'::BLOB,
'123456789abcdef'::BLOB,
'123456789abcdef'::BLOB,
TRUE,
FALSE,
TRUE,
'2025-06-01'::DATE,
1,
1,
1,
1,
1,
1,
1,
1,
1,
1,
1,
1,
'1 year 1 month 1 day'::INTERVAL,
'{"key":"value"}',
1,
1,
1,
'12:34:56'::TIME,
'2025-06-01 12:34:56.789'::TIMESTAMPTZ,
'2025-06-01 12:34:56.789'::TIMESTAMP,
'2025-06-01 12:34:56.789'::DATETIME,
1,
1,
1,
1,
1,
1,
1,
'f81d4fae-7dec-11d0-a765-00a0c91e6bf6',
'string',
'string',
'string',
'string',
'string'
);

.print check the definition of the table

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,BIGINT_val,BIGINT,false,null,false
-- RESULT:1,INT8_val,BIGINT,false,null,false
-- RESULT:2,LONG_val,BIGINT,false,null,false
-- RESULT:3,BLOB_val,BLOB,false,null,false
-- RESULT:4,BYTEA_val,BLOB,false,null,false
-- RESULT:5,BINARY_val,BLOB,false,null,false
-- RESULT:6,VARBINARY_val,BLOB,false,null,false
-- RESULT:7,BOOLEAN_val,BOOLEAN,false,null,false
-- RESULT:8,BOOL_val,BOOLEAN,false,null,false
-- RESULT:9,LOGICAL_val,BOOLEAN,false,null,false
-- RESULT:10,DATE_val,DATE,false,null,false
-- RESULT:11,DECIMAL_val,DECIMAL(18,3),false,null,false
-- RESULT:12,NUMERIC_val,DECIMAL(18,3),false,null,false
-- RESULT:13,DOUBLE_val,DOUBLE,false,null,false
-- RESULT:14,FLOAT8_val,DOUBLE,false,null,false
-- RESULT:15,FLOAT_val,FLOAT,false,null,false
-- RESULT:16,FLOAT4_val,FLOAT,false,null,false
-- RESULT:17,REAL_val,FLOAT,false,null,false
-- RESULT:18,HUGEINT_val,HUGEINT,false,null,false
-- RESULT:19,INTEGER_val,INTEGER,false,null,false
-- RESULT:20,INT4_val,INTEGER,false,null,false
-- RESULT:21,INT_val,INTEGER,false,null,false
-- RESULT:22,SIGNED_val,INTEGER,false,null,false
-- RESULT:23,INTERVAL_val,INTERVAL,false,null,false
-- RESULT:24,JSON_val,JSON,false,null,false
-- RESULT:25,SMALLINT_val,SMALLINT,false,null,false
-- RESULT:26,INT2_val,SMALLINT,false,null,false
-- RESULT:27,SHORT_val,SMALLINT,false,null,false
-- RESULT:28,TIME_val,TIME,false,null,false
-- RESULT:29,TIMESTAMPTZ_val,TIMESTAMP WITH TIME ZONE,false,null,false
-- RESULT:30,TIMESTAMP_val,TIMESTAMP,false,null,false
-- RESULT:31,DATETIME_val,TIMESTAMP,false,null,false
-- RESULT:32,TINYINT_val,TINYINT,false,null,false
-- RESULT:33,INT1_val,TINYINT,false,null,false
-- RESULT:34,UBIGINT_val,UBIGINT,false,null,false
-- RESULT:35,UHUGEINT_val,UHUGEINT,false,null,false
-- RESULT:36,UINTEGER_val,UINTEGER,false,null,false
-- RESULT:37,USMALLINT_val,USMALLINT,false,null,false
-- RESULT:38,UTINYINT_val,UTINYINT,false,null,false
-- RESULT:39,UUID_val,UUID,false,null,false
-- RESULT:40,VARCHAR_val,VARCHAR,false,null,false
-- RESULT:41,CHAR_val,VARCHAR,false,null,false
-- RESULT:42,BPCHAR_val,VARCHAR,false,null,false
-- RESULT:43,TEXT_val,VARCHAR,false,null,false
-- RESULT:44,STRING_val,VARCHAR,false,null,false
PRAGMA table_info('types');

.print check the inserted data
-- RESULT:BIGINT_val,INT8_val,LONG_val,BLOB_val,BYTEA_val,BINARY_val,VARBINARY_val,BOOLEAN_val,BOOL_val,LOGICAL_val,DATE_val,DECIMAL_val,NUMERIC_val,DOUBLE_val,FLOAT8_val,FLOAT_val,FLOAT4_val,REAL_val,HUGEINT_val,INTEGER_val,INT4_val,INT_val,SIGNED_val,INTERVAL_val,JSON_val,SMALLINT_val,INT2_val,SHORT_val,TIME_val,TIMESTAMPTZ_val,TIMESTAMP_val,DATETIME_val,TINYINT_val,INT1_val,UBIGINT_val,UHUGEINT_val,UINTEGER_val,USMALLINT_val,UTINYINT_val,UUID_val,VARCHAR_val,CHAR_val,BPCHAR_val,TEXT_val,STRING_val
-- RESULT:1,1,1,123456789abcdef,123456789abcdef,123456789abcdef,123456789abcdef,true,false,true,20250601120000,1.000,1.000,1,1,1,1,1,1,1,1,1,1,1 year 1 month 1 day,{"key":"value"},1,1,1,12:34:56,20250601123456,20250601123456,20250601123456,1,1,1,1,1,1,1,f81d4fae-7dec-11d0-a765-00a0c91e6bf6,string,string,string,string,string
select * from types;
