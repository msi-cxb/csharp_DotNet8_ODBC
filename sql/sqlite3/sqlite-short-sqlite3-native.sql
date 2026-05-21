.conn sqlite3

-- G-003: native SQLite3 driver smoke test
DROP TABLE IF EXISTS native_test;
CREATE TABLE native_test (id INTEGER PRIMARY KEY, name TEXT NOT NULL, score REAL);
INSERT INTO native_test VALUES (1, 'alpha', 1.5), (2, 'beta', 2.5), (3, 'gamma', 3.5);

-- RESULT:id,name,score
-- RESULT:1,alpha,1.5
-- RESULT:2,beta,2.5
-- RESULT:3,gamma,3.5
SELECT id, name, score FROM native_test ORDER BY id;

-- RESULT:cnt
-- RESULT:3
SELECT COUNT(*) AS cnt FROM native_test;
