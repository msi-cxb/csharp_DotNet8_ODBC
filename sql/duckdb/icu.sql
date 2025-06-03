-- https://duckdb.org/2022/01/06/time-zones.html

.echo on
.timer on

INSTALL icu;
LOAD icu;

.print Show the current time zone. The default is set to ICU current time zone.
-- RESULT:name,value,description,input_type,scope
-- RESULT:TimeZone,America/Sao_Paulo,The current time zone,VARCHAR,GLOBAL
SELECT * FROM duckdb_settings() WHERE name = 'TimeZone';

.print Choose a time zone.
SET TimeZone = 'America/Los_Angeles';

.print Emulate Postgres time zone table
-- RESULT:name,abbrev,utc_offset
-- RESULT:ACT,ACT,09:30:00
-- RESULT:AET,AET,10:00:00
-- RESULT:AGT,AGT,-03:00:00
-- RESULT:ART,ART,03:00:00
-- RESULT:AST,AST,-08:00:00
SELECT name, abbrev, utc_offset 
FROM pg_timezone_names() 
ORDER BY 1 
LIMIT 5;

.print Show the current calendar. The default is set to ICUs current locale.
-- RESULT:name,value,description,input_type,scope
-- RESULT:Calendar,gregorian,The current calendar,VARCHAR,GLOBAL
SELECT * FROM duckdb_settings() WHERE name = 'Calendar';

.print  List the available calendars
-- RESULT:name
-- RESULT:roc
-- RESULT:persian
-- RESULT:japanese
-- RESULT:iso8601
-- RESULT:islamic-umalqura
SELECT DISTINCT name FROM icu_calendar_names()
ORDER BY 1 DESC LIMIT 5;

.print  Choose a calendar
SET Calendar = 'japanese';

.print  Extract the current Japanese era number using Tokyo time
SET TimeZone = 'Asia/Tokyo';

-- RESULT:era(CAST('2019-05-01 00:00:00+10' AS TIMESTAMP WITH TIME ZONE)),era(CAST('2019-05-01 00:00:00+09' AS TIMESTAMP WITH TIME ZONE))
-- RESULT:235,236
SELECT
     era('2019-05-01 00:00:00+10'::TIMESTAMPTZ),
     era('2019-05-01 00:00:00+09'::TIMESTAMPTZ);







