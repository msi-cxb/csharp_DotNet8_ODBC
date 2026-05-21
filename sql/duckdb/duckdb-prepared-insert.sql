-- .echo on
-- .timer on
.conn duckdb

PRAGMA version;

-- works in v1.3.2,0b83e5d2f6,Ossivalis
-- breaks in v1.4.1,b390a7c376,Andium

.print use 100,000 insert into statements to insert 100,000 records using duckdb
.print not any faster than regular insert into.

CREATE OR REPLACE TEMPORARY TABLE timer as select 'start' as key, current_localtimestamp() as value;

CREATE OR REPLACE TABLE big_table(id BIGINT, hash VARCHAR, rand DOUBLE, "value" DOUBLE);
PREPARE insert_stmt AS INSERT INTO big_table (id, hash, rand, value) VALUES (?,?,?,?);
BEGIN TRANSACTION;
EXECUTE insert_stmt(1,'704719932875954298',1.0,0.7095996033937675974);
COMMIT;

select * from big_table;

insert into timer values('finish',current_localtimestamp());

select 
    date_diff('milliseconds',(select value from timer where key='start'),(select value from timer where key='finish'))/1000 as delta_seconds,
    count(1) as cnt,
    count(1)/(date_diff('milliseconds',(select value from timer where key='start'),(select value from timer where key='finish'))/1000) as inserts_persecond
from big_table;

select * from big_table limit 5;

select 
    count(1) as cnt,
    avg(id) as id_avg,
    avg(cast(hash as real)) as id_hash,
    avg(rand) as id_rand,
    avg("value") as id_value
from big_table;
