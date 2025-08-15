-- .echo on
-- .timer on
.conn sqlite3

-- DELETE | TRUNCATE | PERSIST | MEMORY | WAL | OFF
-- PRAGMA journal_mode = WAL;
PRAGMA journal_mode;

-- 0 | OFF | 1 | NORMAL | 2 | FULL | 3 | EXTRA
-- PRAGMA synchronous = NORMAL;
PRAGMA synchronous;

-- pages | -kibibytes
-- PRAGMA cache_size = 10000;
PRAGMA cache_size;

--  0 | DEFAULT | 1 | FILE | 2 | MEMORY
-- PRAGMA temp_store = MEMORY;
PRAGMA temp_store;

-- boolean
-- PRAGMA foreign_keys = ON;
PRAGMA foreign_keys;

-- the maximum number of bytes of the database file that will be accessed using memory-mapped I/O.
-- PRAGMA mmap_size = 268435456;
PRAGMA mmap_size;

-- milliseconds
PRAGMA busy_timeout;

