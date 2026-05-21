.echo on
.conn sqlite3

-- =============================================================
-- Test: CLI Args - SQLite3 In-Memory Default
-- Description: Verifies the tool runs correctly with the default
--              :memory: connection (no --dbfile argument).
--              Confirms in-memory SQLite3 works end-to-end.
-- =============================================================

DROP TABLE IF EXISTS cli_test;
CREATE TABLE cli_test (id INTEGER PRIMARY KEY, label TEXT NOT NULL);
INSERT INTO cli_test VALUES (1, 'default'), (2, 'memory');

-- RESULT:id,label
-- RESULT:1,default
-- RESULT:2,memory
SELECT id, label FROM cli_test ORDER BY id;

-- RESULT:cnt
-- RESULT:2
SELECT COUNT(*) AS cnt FROM cli_test;
