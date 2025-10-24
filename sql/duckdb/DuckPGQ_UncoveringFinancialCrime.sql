.echo on
-- .timer on
.conn duckdb

-- https://duckdb.org/2025/10/22/duckdb-graph-queries-duckpgq

-- RESULT:library_version,source_id,codename
-- RESULT:v1.4.1,b390a7c376,Andium
PRAGMA version;

-- RESULT:threads
-- RESULT:6
SELECT current_setting('threads') AS threads;

.print *************************************************
-- FORCE INSTALL duckpgq from '.\local_extensions';
INSTALL duckpgq FROM community;
LOAD duckpgq;

ATTACH 'https://blobs.duckdb.org/data/finbench.duckdb' AS finbench;
USE finbench;

-- RESULT:num_persons,num_accounts,num_transfers
-- RESULT:785,2055,8132
SELECT
    (SELECT count(*) FROM Person) AS num_persons,
    (SELECT count(*) FROM Account) AS num_accounts,
    (SELECT count(*) FROM AccountTransferAccount) AS num_transfers;

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

USE test;

DETACH finbench;
