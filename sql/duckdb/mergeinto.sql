-- .echo on
-- .timer on
.conn duckdb

CREATE TABLE Stock(item_id INTEGER, balance INTEGER);
INSERT INTO Stock VALUES (10, 2200), (20, 1900);

WITH new_stocks(item_id, volume) AS (VALUES (20, 2200), (30, 1900))
    MERGE INTO Stock USING new_stocks USING (item_id)
    WHEN MATCHED THEN UPDATE SET balance = balance + volume
    WHEN NOT MATCHED THEN INSERT VALUES (new_stocks.item_id, new_stocks.volume);
FROM Stock;

-- RESULT:item_id,balance
-- RESULT:10,2200
-- RESULT:20,4100
-- RESULT:30,1900
select * from Stock;
