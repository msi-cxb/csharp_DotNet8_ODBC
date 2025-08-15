-- .echo on
-- .timer on
.conn duckdb

.print dbfolder [[__DBFOLDER__]]
.print datafolder [[__DATAFOLDER__]]

-- https://duckdb.org/2025/08/15/ml-data-preprocessing.html
-- TL;DR: In this post, we show how to perform essential machine learning data preprocessing tasks, 
-- like missing value imputation, categorical encoding, and feature scaling, directly in DuckDB 
-- using SQL. This approach not only simplifies workflows, but also takes advantage of DuckDB’s 
-- high-performance, in-process execution engine for fast, efficient data preparation.

-- test program deletes test.db so load/persist into basicFeatureEngineering.db
ATTACH '[[__DBFOLDER__]]\basicFeatureEngineering.db' AS basicFeatureEngineering;
USE basicFeatureEngineering;

.print ********************************************
.print Data Preparation

-- requires internet access
-- uncomment this for first run to get the data...
-- CREATE OR REPLACE TABLE financial_trx AS
    -- FROM read_csv('https://blobs.duckdb.org/data/financial_fraud_detection_dataset.csv');

SELECT database_name,schema_name,table_name,estimated_size,column_count FROM duckdb_tables();

-- RESULT:column_name,column_type,count,null_percentage,min
-- RESULT:transaction_id,VARCHAR,5000000,0.00,T100000
-- RESULT:timestamp,TIMESTAMP,5000000,0.00,2023-01-01 00:09:26.241974
-- RESULT:sender_account,VARCHAR,5000000,0.00,ACC100000
-- RESULT:receiver_account,VARCHAR,5000000,0.00,ACC100000
-- RESULT:amount,DOUBLE,5000000,0.00,0.01
-- RESULT:transaction_type,VARCHAR,5000000,0.00,deposit
-- RESULT:merchant_category,VARCHAR,5000000,0.00,entertainment
-- RESULT:location,VARCHAR,5000000,0.00,Berlin
-- RESULT:device_used,VARCHAR,5000000,0.00,atm
-- RESULT:is_fraud,BOOLEAN,5000000,0.00,false
-- RESULT:fraud_type,VARCHAR,5000000,96.41,card_not_present
-- RESULT:time_since_last_transaction,DOUBLE,5000000,17.93,-8777.814181944444
-- RESULT:spending_deviation_score,DOUBLE,5000000,0.00,-5.26
-- RESULT:velocity_score,BIGINT,5000000,0.00,1
-- RESULT:geo_anomaly_score,DOUBLE,5000000,0.00,0.0
-- RESULT:payment_channel,VARCHAR,5000000,0.00,ACH
-- RESULT:ip_address,VARCHAR,5000000,0.00,0.0.102.150
-- RESULT:device_hash,VARCHAR,5000000,0.00,D1000002
FROM (SUMMARIZE financial_trx)
SELECT
    column_name,
    column_type,
    count,
    null_percentage,
    min;

.print ********************************************
.print Feature Encoding


.print ********************************************
.print One-Hot Encoding

-- RESULT:transaction_type,deposit_onehot,payment_onehot,transfer_onehot,withdrawal_onehot
-- RESULT:deposit,1,0,0,0
-- RESULT:payment,0,1,0,0
-- RESULT:transfer,0,0,1,0
-- RESULT:withdrawal,0,0,0,1
FROM financial_trx
SELECT DISTINCT
    transaction_type,
    deposit_onehot: (transaction_type = 'deposit')::INT,
    payment_onehot: (transaction_type = 'payment')::INT,
    transfer_onehot: (transaction_type = 'transfer')::INT,
    withdrawal_onehot: (transaction_type = 'withdrawal')::INT
ORDER BY transaction_type;

-- RESULT:transaction_type,deposit_onehot,payment_onehot,transfer_onehot,withdrawal_onehot
-- RESULT:deposit,1,0,0,0
-- RESULT:payment,0,1,0,0
-- RESULT:transfer,0,0,1,0
-- RESULT:withdrawal,0,0,0,1
PIVOT financial_trx
ON transaction_type
USING coalesce(max(transaction_type = transaction_type)::INT, 0) AS onehot
GROUP BY transaction_type
ORDER BY transaction_type;

WITH onehot_trx_type AS (
    PIVOT financial_trx
    ON transaction_type
    USING coalesce(max(transaction_type = transaction_type)::INT, 0) AS onehot
    GROUP BY transaction_type
), onehot_payment_channel AS (
    PIVOT financial_trx
    ON payment_channel
    USING coalesce(max(payment_channel = payment_channel)::INT, 0) AS onehot
    GROUP BY payment_channel
)
SELECT
    financial_trx.*,
    onehot_trx_type.* LIKE '%\_onehot' ESCAPE '\',
    onehot_payment_channel.* LIKE '%\_onehot' ESCAPE '\'
FROM financial_trx
INNER JOIN onehot_trx_type USING (transaction_type)
INNER JOIN onehot_payment_channel USING (payment_channel)
limit 5;

-- ' to make the sql syntax coloring in notepad++ happy(er)

.print ********************************************
.print Ordinal Encoding

-- RESULT:transaction_type,trx_type_oe,number_trx
-- RESULT:deposit,0,1250593
-- RESULT:payment,1,1250438
-- RESULT:transfer,2,1250334
-- RESULT:withdrawal,3,1248635
WITH trx_type_ordinal_encoded AS (
    SELECT
        transaction_type,
        trx_type_oe: row_number() OVER (ORDER BY transaction_type) - 1
    FROM (
        SELECT DISTINCT transaction_type
        FROM financial_trx
    )
)
SELECT
    transaction_type,
    trx_type_oe,
    number_trx: count(*)
FROM financial_trx
INNER JOIN trx_type_ordinal_encoded USING (transaction_type)
GROUP BY ALL
ORDER BY trx_type_oe;


.print ********************************************
.print Label Encoding

-- RESULT:transaction_type,trx_type_le,number_trx
-- RESULT:deposit,0,1250593
-- RESULT:payment,2,1250438
-- RESULT:transfer,3,1250334
-- RESULT:withdrawal,1,1248635
WITH trx_type_label_encoded AS (
    SELECT
        transaction_type,
        trx_type_le: row_number() OVER () - 1
    FROM (
        SELECT DISTINCT transaction_type
        FROM financial_trx
    )
)
SELECT
    transaction_type,
    trx_type_le,
    number_trx: count(*)
FROM financial_trx
INNER JOIN trx_type_label_encoded USING (transaction_type)
GROUP BY ALL
ORDER BY transaction_type;

-- query is non-deterministic so can't compare results
WITH trx_ref AS (
    SELECT trx_type_values: array_agg(DISTINCT transaction_type)
    FROM financial_trx
)
SELECT
    transaction_type,
    trx_type_le: list_position(trx_type_values, transaction_type) - 1,
    number_trx: count(*)
FROM
    financial_trx,
    trx_ref
GROUP BY ALL
ORDER BY transaction_type;

.print ********************************************
.print Feature Scaling

SET threads = 1;

CREATE OR REPLACE TABLE financial_trx_training AS
FROM financial_trx
USING SAMPLE 80 PERCENT (reservoir, 256);

SET threads = 8;

CREATE OR REPLACE TABLE financial_trx_testing AS
FROM financial_trx
ANTI JOIN financial_trx_training USING (transaction_id);

-- We configure DuckDB to use a single-thread during sampling and set a seed to make sure 
-- that the sampling is reproducible. We also apply the reservoir sampling strategy to 
-- have exactly 80% of the records in the resulting sample.

-- RESULT:database_name,schema_name,table_name,estimated_size,column_count
-- RESULT:basicFeatureEngineering,main,financial_trx,5000000,18
-- RESULT:basicFeatureEngineering,main,financial_trx_testing,1000000,18
-- RESULT:basicFeatureEngineering,main,financial_trx_training,4000000,18
SELECT database_name,schema_name,table_name,estimated_size,column_count FROM duckdb_tables() order by database_name,table_name;

.print ********************************************
.print Standard Scaling

WITH scaling_params AS (
    SELECT
        avg_velocity_score: avg(velocity_score),
        stddev_pop_velocity_score: stddev_pop(velocity_score)
    FROM financial_trx_training
)
SELECT
    ss_velocity_score: (velocity_score - avg_velocity_score) /
        stddev_pop_velocity_score
FROM
    financial_trx_testing,
    scaling_params
LIMIT 10;

CREATE OR REPLACE MACRO standard_scaler(val, avg_val, std_val) AS
    (val - avg_val) / std_val;
CREATE OR REPLACE MACRO scaling_params(table_name, column_list) AS TABLE
    FROM query_table(table_name)
    SELECT
        "avg_\0": avg(columns(column_list)),
        "std_\0": stddev_pop(columns(column_list));
SELECT
    ss_velocity_score: standard_scaler(
        velocity_score,
        avg_velocity_score,
        std_velocity_score
    ),
    ss_spending_deviation_score: standard_scaler(
        spending_deviation_score,
        avg_spending_deviation_score,
        std_spending_deviation_score
    ) 
FROM financial_trx_testing,
    scaling_params(
        'financial_trx_training',
        ['velocity_score', 'spending_deviation_score']
    )
LIMIT 10;

.print ********************************************
.print Min-Max Scaling

CREATE OR REPLACE MACRO scaling_params(table_name, column_list) AS TABLE
    FROM query_table(table_name)
    SELECT
        "avg_\0": avg(columns(column_list)),
        "std_\0": stddev_pop(columns(column_list)),
        "min_\0": min(columns(column_list)),
        "max_\0": max(columns(column_list));
        
CREATE OR REPLACE MACRO min_max_scaler(val, min_val, max_val) AS
    (val - min_val) / nullif(max_val - min_val, 0);

SELECT
    min_max_velocity_score: min_max_scaler(
        velocity_score,
        min_velocity_score,
        max_velocity_score
    ),
    min_max_spending_deviation_score: min_max_scaler(
        spending_deviation_score,
        min_spending_deviation_score,
        max_spending_deviation_score
    )
FROM financial_trx_testing,
    scaling_params(
        'financial_trx_training',
        ['velocity_score', 'spending_deviation_score']
    )
LIMIT 10;


.print ********************************************
.print Robust Scaling

CREATE OR REPLACE MACRO scaling_params(table_name, column_list) AS TABLE
    FROM query_table(table_name)
    SELECT
        "avg_\0": avg(columns(column_list)),
        "std_\0": stddev_pop(columns(column_list)),
        "min_\0": min(columns(column_list)),
        "max_\0": max(columns(column_list)),
        "q25_\0": quantile_cont(columns(column_list), 0.25),
        "q50_\0": quantile_cont(columns(column_list), 0.50),
        "q75_\0": quantile_cont(columns(column_list), 0.75);

CREATE OR REPLACE MACRO robust_scaler(val, q25_val, q50_val, q75_val) AS
    (val - q50_val) / nullif(q75_val - q25_val, 0);

SELECT
    rs_velocity_score: robust_scaler(
        velocity_score,
        q25_velocity_score,
        q50_velocity_score,
        q75_velocity_score
    ),
    rs_spending_deviation_score: robust_scaler(
        spending_deviation_score,
        q25_spending_deviation_score,
        q50_spending_deviation_score,
        q75_spending_deviation_score
    )
FROM financial_trx_testing,
    scaling_params(
        'financial_trx_training',
        ['velocity_score', 'spending_deviation_score']
    )
LIMIT 10;

.print ********************************************
.print Handling Missing Values

CREATE OR REPLACE MACRO scaling_params(table_name, column_list) AS TABLE
    FROM query_table(table_name)
    SELECT
        "avg_\0": avg(columns(column_list)),
        "std_\0": stddev_pop(columns(column_list)),
        "min_\0": min(columns(column_list)),
        "max_\0": max(columns(column_list)),
        "q25_\0": quantile_cont(columns(column_list), 0.25),
        "q50_\0": quantile_cont(columns(column_list), 0.50),
        "q75_\0": quantile_cont(columns(column_list), 0.75),
        "median_\0": median(columns(column_list));

SELECT
    time_since_last_transaction_with_0: coalesce(time_since_last_transaction, 0),
    time_since_last_transaction_with_mean: coalesce(time_since_last_transaction, avg_time_since_last_transaction),
    time_since_last_transaction_with_median: coalesce(time_since_last_transaction, median_time_since_last_transaction)
FROM
    financial_trx_testing,
    scaling_params('financial_trx_training', ['time_since_last_transaction'])
WHERE time_since_last_transaction IS NULL
LIMIT 10;








.print ********************************************
.print switch back to test.db and detach basicFeatureEngineering
USE test;
DETACH basicFeatureEngineering;
