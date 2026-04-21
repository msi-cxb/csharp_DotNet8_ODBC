-- .echo on
-- .timer on
.conn duckdb

.print dbfolder [[__DBFOLDER__]]
.print datafolder [[__DATAFOLDER__]]

-- 5000 x 5000 --> 25,000,000 rows

CREATE OR REPLACE TABLE big_company (
    id BIGINT,
    hash UINT64,
    rand DOUBLE,
    value DOUBLE
);

SELECT SETSEED(0.42);

INSERT INTO big_company 
    select 
        (i+j) AS id, 
        hash(i+j) AS hash, 
        IF (j % 2, true, false) AS value, 
        RANDOM() as value 
    from 
        generate_series(1, 5000) s(i) 
CROSS JOIN generate_series(1, 5000) t(j);

copy ( 
    select * from big_company
) TO '[[__DATAFOLDER__]]\big_company.csv' (HEADER, DELIMITER ',', OVERWRITE_OR_IGNORE);

-- RESULT:cnt,avg_rand,min_rand,max_rand,min_hash,max_hash
-- RESULT:25000000,0.5,0,1,168578917420164,1.8446581744839424E+19
SELECT 
    count(1) as cnt,
    avg(rand) as avg_rand, 
    min(rand) as min_rand, 
    max(rand) as max_rand,
    min(hash) as min_hash, 
    max(hash) as max_hash 
FROM '[[__DATAFOLDER__]]\big_company.csv';

CREATE OR REPLACE TABLE big_company_import AS SELECT * FROM  '[[__DATAFOLDER__]]\big_company.csv';

-- RESULT:cid,name,type,notnull,dflt_value,pk
-- RESULT:0,id,BIGINT,false,null,false
-- RESULT:1,hash,DOUBLE,false,null,false
-- RESULT:2,rand,DOUBLE,false,null,false
-- RESULT:3,value,DOUBLE,false,null,false
PRAGMA table_info('big_company_import');

-- RESULT:cnt,avg_rand,min_rand,max_rand,min_hash,max_hash
-- RESULT:25000000,0.5,0,1,168578917420164,1.8446581744839424E+19
SELECT 
    count(1) as cnt,
    avg(rand) as avg_rand, 
    min(rand) as min_rand, 
    max(rand) as max_rand,
    min(hash) as min_hash, 
    max(hash) as max_hash 
FROM big_company_import;
