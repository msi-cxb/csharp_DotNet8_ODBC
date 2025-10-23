.echo on
-- .timer on
.conn duckdb

.print *************************************************
.print
.print DuckDB and Graph Queries
.print
.print *************************************************

PRAGMA version;

-- remove database to start fresh
-- .system del /Q [[__DBFOLDER__]]\postgresql_sqlite_scanner.db > nul 2>&1

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
ORDER BY number_of_transactions DESC, avg_amount ASC
LIMIT 5;

DROP PROPERTY GRAPH finbench;

USE test;

DETACH finbench;
