-- https://duckdb.org/docs/stable/extensions/extension_distribution

-- don't need to run this one normally as it is used to (re)load extensions
-- .quit

.echo on
-- .timer on
.conn duckdb

PRAGMA version;

.print UPDATE EXTENSIONS;

.print ****************************************************************************
.print FORCE INSTALL causes extension to be installed from .\local_extensions instead of internet
.print INSTALL copies to C:\Users\charlie\.duckdb\extensions 
.print ****************************************************************************

-- FORCE INSTALL spatial from '.\extensions\duckdb';
INSTALL spatial;
LOAD spatial;

-- FORCE INSTALL sqlite_scanner from '.\extensions\duckdb';
INSTALL sqlite_scanner;
LOAD sqlite_scanner;

-- FORCE INSTALL fts from '.\extensions\duckdb';
INSTALL fts;
LOAD fts;

-- FORCE INSTALL icu from '.\extensions\duckdb';
INSTALL icu;
LOAD icu;

-- FORCE INSTALL postgres from '.\extensions\duckdb';
INSTALL postgres;
LOAD postgres;

-- FORCE INSTALL ducklake from '.\extensions\duckdb';
INSTALL ducklake;
LOAD ducklake;

-- FORCE INSTALL excel from '.\extensions\duckdb';
INSTALL excel;
LOAD excel;

-- FORCE INSTALL h3 from '.\extensions\duckdb';
INSTALL h3 FROM community;
LOAD h3;

-- FORCE INSTALL tpch from '.\extensions\duckdb';
INSTALL tpch;
LOAD tpch;

.print webbed now available for duckdb v1.4.1
-- FORCE INSTALL webbed from '.\extensions\duckdb';
INSTALL webbed;
LOAD webbed;

-- FORCE INSTALL shellfs from '.\extensions\duckdb';
install shellfs from community;
load shellfs;

-- FORCE INSTALL duckpgq from '.\extensions\duckdb';
install duckpgq from community;
load duckpgq;

-- FORCE INSTALL tarfs from '.\extensions\duckdb';
-- RESULT-ERROR:HTTP Error: Failed to download extension "tarfs" at URL "http://community-extensions.duckdb.org/v1.4.1/windows_amd64/tarfs.duckdb_extension.gz" (HTTP 404)
INSTALL tarfs FROM community;
-- RESULT-ERROR:IO Error: Extension "C:\Users\charlie\.duckdb\extensions\v1.4.1\windows_amd64\tarfs.duckdb_extension" not found.
LOAD tarfs;

SELECT extension_name,loaded,installed,extension_version FROM duckdb_extensions() where installed = true;
