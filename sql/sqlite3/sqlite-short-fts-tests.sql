.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: sqlite3_fts_tests
-- Description: Full-text search tests - FTS4 and FTS5 virtual tables
-- Source: sqlite3_fts_tests in sqliteODBC_tests.vbs (line 4222)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === fts4 ===

DROP TABLE IF EXISTS pages;
CREATE VIRTUAL TABLE pages USING fts4(title, body);

INSERT INTO pages(docid, title, body) VALUES(53, 'Home Page', 'SQLite is a software...');
INSERT INTO pages(title, body) VALUES('Download', 'All SQLite source code...');
INSERT INTO pages(title, body) VALUES('Upload', 'Upload SQLite src code...');

UPDATE pages SET title = 'Download SQLite' WHERE rowid = 54;

INSERT INTO pages(pages) VALUES('optimize');

SELECT * FROM pages WHERE pages MATCH 'sqlite';
SELECT * FROM pages WHERE pages MATCH 's* code';

.print === fts5 ===

DROP TABLE IF EXISTS posts;
CREATE VIRTUAL TABLE posts USING FTS5(title, body);

INSERT INTO posts(title,body)
VALUES('Learn SQlite FTS5','This tutorial teaches you how to perform full-text search using FTS5'),
    ('Advanced SQlite Full-text Search','Show you some advanced techniques in SQLite full-text searching'),
    ('SQLite SQLite SQLite SQLite ','SQLite SQLite SQLite SQLite SQLite SQLite SQLite SQLite SQLite SQLite '),
    ('SQLite Tutorial','Help you learn SQLite quickly and use SQLite effectively');

SELECT * FROM posts;

.print === fts5 full text search ===

SELECT * FROM posts WHERE posts MATCH 'fts5';
SELECT * FROM posts WHERE posts = 'fts5';
SELECT * FROM posts('fts5');
SELECT * FROM posts WHERE posts MATCH 'text' ORDER BY rank;
SELECT * FROM posts WHERE posts MATCH 'learn SQLite';
SELECT * FROM posts WHERE posts = 'search*';
SELECT * FROM posts WHERE posts MATCH 'learn NOT text';
SELECT * FROM posts WHERE posts MATCH 'learn OR text';
SELECT * FROM posts WHERE posts MATCH 'sqlite AND searching';
SELECT * FROM posts WHERE posts MATCH 'search AND sqlite OR help';
SELECT * FROM posts WHERE posts MATCH 'search AND (sqlite OR help)';

.print === fts5 highlight ===

SELECT
    highlight(posts,0, '<b>', '</b>') title,
    highlight(posts,1, '<b>', '</b>') body
FROM posts WHERE posts MATCH 'SQLite'
ORDER BY rank;

.print === fts5 bm25 rank ===

SELECT bm25(posts) AS accuracy, * FROM posts WHERE posts MATCH 'sqlite' ORDER BY bm25(posts);
SELECT rank, * FROM posts WHERE posts MATCH 'sqlite' ORDER BY rank;

.print === fts5 snippet ===

SELECT
    snippet(posts,0,'<<','>>','...',3) title,
    snippet(posts,1,'<<','>>','...',6) body
FROM posts WHERE posts MATCH 'sqLite';

INSERT INTO timer VALUES('file', 'the end', unixepoch('now', 'subsec'));

.print time results
SELECT
    task_name,
    note,
    strftime('%H:%M:%f', ts_msec_delta, 'unixepoch') AS delta
FROM (
    SELECT *,
        ts_msec - LAG(ts_msec, 1) OVER (PARTITION BY task_name ORDER BY ts_msec) AS ts_msec_delta
    FROM (SELECT *, row_number() OVER () AS rowid FROM timer)
) WHERE ts_msec_delta IS NOT NULL ORDER BY rowid;
