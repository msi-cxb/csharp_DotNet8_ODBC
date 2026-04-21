-- .echo on
-- .timer on
.conn duckdb

PRAGMA version;

.print dbfolder [[__DBFOLDER__]]
.print datafolder [[__DATAFOLDER__]]

