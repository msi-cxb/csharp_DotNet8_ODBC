.echo on
-- .timer on
.conn duckdb

-- https://duckdb.org/2025/10/22/duckdb-graph-queries-duckpgq

.print *************************************************
.print version 1.5.2 not currently available
.next

.delete [[__DBFOLDER__]]\finbench_local.duckdb

.print *************************************************
dPRAGMA version;

-- RESULT:threads
-- RESULT:6
SELECT current_setting('threads') AS threads;

.print *************************************************
-- FORCE INSTALL duckpgq from '.\extensions\duckdb';
INSTALL duckpgq FROM community;
LOAD duckpgq;

.print *************************************************
.print load finbench from 'https://blobs.duckdb.org/data/finbench.duckdb'
ATTACH 'https://blobs.duckdb.org/data/finbench.duckdb' AS finbench_remote;
ATTACH '[[__DBFOLDER__]]\finbench_local.duckdb' AS finbench_local;
COPY FROM DATABASE finbench_remote TO finbench_local;
USE finbench_local;
DETACH finbench_remote;

-- RESULT:num_persons,num_accounts,num_transfers
-- RESULT:785,2055,8132
SELECT
    (SELECT count(*) FROM Person) AS num_persons,
    (SELECT count(*) FROM Account) AS num_accounts,
    (SELECT count(*) FROM AccountTransferAccount) AS num_transfers;
.next

CREATE PROPERTY GRAPH finbench
VERTEX TABLES (
    Person,
    Account
)
EDGE TABLES (
    AccountTransferAccount
        SOURCE KEY (fromId) REFERENCES Account (accountId)
        DESTINATION KEY (toId) REFERENCES Account (accountId)
        LABEL Transfer,
    PersonOwnAccount
        SOURCE KEY (personId) REFERENCES Person (personId)
        DESTINATION KEY (accountId) REFERENCES Account (accountId)
        LABEL PersonOwn
);

-- RESULT:fromName,number_of_transactions,avg_amount,toName
-- RESULT:Noe Trites,1,49365.04,Dale Croucher
-- RESULT:Madeleine Bussing,1,46663.56,Delphine Primiano
-- RESULT:Bonnie Centeno,1,46663.56,Maile Boon
-- RESULT:Darci Sheedy,1,44856.02,Carmella Estelle
-- RESULT:Marguerita Gurne,1,44393.68,Delphine Primiano
SELECT
    fromName,
    count(amount) AS number_of_transactions,
    round(avg(amount), 2) AS avg_amount,
    toName
FROM GRAPH_TABLE (finbench
    MATCH (a:Account)-[t:Transfer]->(a2:Account)
    COLUMNS (a.nickname AS fromName,
             t.amount,
             a2.nickname AS toName
            )
)
GROUP BY ALL
HAVING avg_amount < 50_000
ORDER BY number_of_transactions DESC, avg_amount DESC
LIMIT 5;

FROM GRAPH_TABLE(finbench
    MATCH p = ANY SHORTEST
                  (p:Person)-[o1:PersonOwn]->(a1:Account)
                  -[t:Transfer]->+
                  (a2:Account)<-[o2:PersonOwn]-(p:Person)
WHERE
    p.personId = 125 AND a1.accountId <> a2.accountId
    COLUMNS (
        path_length(p) AS path_length,
        a1.accountId AS start_account,
        a2.accountId AS end_account
    )
)
ORDER BY path_length;

DROP PROPERTY GRAPH finbench;

.print ****************************************
.print To ensure a SQL script returns to its initial database—whether that 
.print is a file or in-memory—you can always use the command USE memory;.
USE memory;
DETACH finbench_local;
