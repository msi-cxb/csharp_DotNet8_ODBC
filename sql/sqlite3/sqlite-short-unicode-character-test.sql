.echo on
-- .timer on
.conn sqlite3

-- =============================================================
-- Test: unicodeCharacterTest
-- Description: Unicode character support - emoji and special characters in SQLite
-- Source: unicodeCharacterTest in sqliteODBC_tests.vbs (line 3214)
-- Connection: sqlite3
-- =============================================================

DROP TABLE IF EXISTS timer;
CREATE TABLE timer (task_name TEXT, note TEXT, ts_msec REAL);
INSERT INTO timer VALUES('file', 'the start', unixepoch('now', 'subsec'));

.print === unicodeCharacterTest ===

DROP TABLE IF EXISTS tblCountry;

CREATE TABLE tblCountry (
    Country TEXT,
    ISO2 TEXT,
    ISO3 TEXT,
    ISONum INT,
    PRIMARY KEY (Country, ISO2, ISO3, ISONum)
);

-- Note: second and third entries contain unicode fox: 🦊 and A with circle on top: Å
INSERT INTO tblCountry (Country, ISO2, ISO3, ISONum) VALUES
    ('Afghanistan','AF','AFG',4),
    ('🦊y Lady Land','XX','AFG',4),
    ('Å Islands','AX','ALA',248);

SELECT * FROM tblCountry;

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
