.echo on
.timer on

-- RESULT:vers,srcId
-- RESULT:3.49.2,2025-05-07 10:39:52 17144570b0d96ae63cd6f3edca39e27ebd74925252bbaf6723bcb2f6b4861fb1
SELECT sqlite_version() as vers, sqlite_source_id() as srcId;
