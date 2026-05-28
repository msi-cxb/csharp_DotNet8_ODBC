.echo on
-- .timer on
.conn duckdb

select version() as version;

-- https://duckdb.org/docs/current/sql/functions/timestamptz
-- to_timestamp(double)	Converts seconds since the epoch to a timestamp with time zone.

-- UNIX Epoch 1284352323.123
-- local 20100912093203 --> 2010-09-12 21:32:03.123-07 --> Sunday, September 12, 2010, at 9:32:03.123 PM PDT
-- UTC   20100913043203 --> 2010-09-13 04:32:03.123+00 --> Monday, September 13, 2010, at 04:32:03.123 UTC

.print *********************************************
.print check the timezone...everything below assumes PDT (America/Phoenix)
SELECT value FROM duckdb_settings() WHERE name = 'TimeZone';

.print *********************************************
.print is ICU loaded? This can affect results --> Yes for both interfaces
-- RESULT:extension_name,loaded,installed
-- RESULT:icu,true,true
SELECT extension_name, loaded, installed FROM duckdb_extensions() WHERE extension_name = 'icu';

.print *********************************************
.print native and odbc produce different result...plus no fraction
.print ODBC trims timezone and then maps to local time --> 20100912093203
.print native maintains timezone so this outputs UTC   --> 20100913043203
SELECT to_timestamp(1284352323.123) AS t;

.print *********************************************
.print using strftime() prints local time with fraction and offset regardless of interface
-- RESULT:local_time
-- RESULT:Sunday, 12 September 2010 - 09:32:03.123000 PM -07 America/Phoenix
SELECT strftime(to_timestamp(1284352323.123), '%A, %-d %B %Y - %I:%M:%S.%f %p %z %Z') as local_time;

.print *********************************************
.print using strftime() prints local time in ISO 8601 format with T regardless of interface
-- RESULT:local_time
-- RESULT:2010-09-12T21:32:03.123000
SELECT strftime(to_timestamp(1284352323.123), '%Y-%m-%dT%H:%M:%S.%f') as local_time;

.print *********************************************
.print adding ::VARCHAR prints local time with fraction and offset regardless of interface
-- RESULT:local_time
-- RESULT:2010-09-12 21:32:03.123-07
SELECT to_timestamp(1284352323.123)::VARCHAR AS local_time;

.print *********************************************
.print adding ::TIMESTAMP prints local time with no fraction or offset regardless of interface
-- RESULT:local_time
-- RESULT:20100912093203
SELECT to_timestamp(1284352323.123)::TIMESTAMP AS local_time;

.print *********************************************
.print adding ::TIMESTAMP::VARCHAR prints local time in ISO 8601 (no T) regardless of interface
-- RESULT:local_time
-- RESULT:2010-09-12 21:32:03.123
SELECT to_timestamp(1284352323.123)::TIMESTAMP::VARCHAR AS local_time;

.print *********************************************
.print adding ::TIMESTAMPTZ different output per interface
.print ODBC displays local      --> 20100912093203
.print with native displays UTC --> 20100913043203
SELECT to_timestamp(1284352323.123)::TIMESTAMPTZ AS t;

.print *********************************************
.print set timezone --> UTC
 SET TimeZone='UTC';
-- RESULT:value
-- RESULT:UTC
SELECT value FROM duckdb_settings() WHERE name = 'TimeZone';

.print *********************************************
.print setting TimeZone does not help when using ::TIMESTAMPTZ...
.print ODBC displays local      --> 20100912093203
.print with native displays UTC --> 20100913043203
SELECT to_timestamp(1284352323.123)::TIMESTAMPTZ AS t;

.print *********************************************
.print however, when outputing using ::VARCHAR it does respect TimeZone for both interfaces
-- RESULT:utc_time
-- RESULT:2010-09-13 04:32:03.123+00
SELECT to_timestamp(1284352323.123)::VARCHAR AS utc_time;

.print *********************************************
.print strftime() with format string that mimics ::VARCHAR, respects TimeZone for both interfaces
-- RESULT:utc_time
-- RESULT:2010-09-13 04:32:03.123000+00
SELECT strftime(to_timestamp(1284352323.123), '%Y-%m-%d %H:%M:%S.%f%z') as utc_time;

.print *********************************************
.print reset timezone --> local
RESET TimeZone;
-- RESULT:value
-- RESULT:America/Phoenix
SELECT value FROM duckdb_settings() WHERE name = 'TimeZone';

.print ************************************************************************
.print ************************************************************************
.print ****                                                   *****************
.print **** These should all display UTC with both interfaces *****************
.print ****                                                   *****************
.print ************************************************************************
.print ************************************************************************
.print millisecond fraction in ISO 8601 format no T with fraction
-- RESULT:utc_time
-- RESULT:2010-09-13 04:32:03.123000
SELECT strftime(to_timestamp(1284352323.123)::TIMESTAMPTZ AT TIME ZONE 'UTC', '%Y-%m-%d %H:%M:%S.%f') AS utc_time;

.print *********************************************
.print microsecond fraction in ISO 8601 format no T with fraction
-- RESULT:utc_time
-- RESULT:2010-09-13 04:32:03.000123
SELECT strftime(to_timestamp(1284352323.000123)::TIMESTAMPTZ AT TIME ZONE 'UTC', '%Y-%m-%d %H:%M:%S.%f') AS utc_time;

.print *********************************************
.print replace strftime with ::VARCHAR ISO 8601 format no T with fraction
-- RESULT:utc_time
-- RESULT:2010-09-13 04:32:03.123
SELECT (to_timestamp(1284352323.123)::TIMESTAMPTZ AT TIME ZONE 'UTC')::VARCHAR as utc_time;

.print *********************************************
.print do not need ::TIMESTAMPTZ ISO 8601 format no T with fraction
-- RESULT:utc_time
-- RESULT:2010-09-13 04:32:03.123
SELECT (to_timestamp(1284352323.123) AT TIME ZONE 'UTC')::VARCHAR as utc_time;

.print ************************************************************************
.print unix epoch in seconds, so need to convert to milliseconds before passing to epoch_ms
-- RESULT:utc_time
-- RESULT:2010-09-13 04:32:03.123000
SELECT strftime(epoch_ms((1284352323.123*1000)::BIGINT), '%Y-%m-%d %H:%M:%S.%f') AS utc_time;

.print *********************************************
.print if you set TimeZone to UTC then these also work...
SET TimeZone='UTC';

.print *********************************************
.print however, when outputing using ::VARCHAR it does respect TimeZone for both interfaces
-- RESULT:utc_time
-- RESULT:2010-09-13 04:32:03.123+00
SELECT to_timestamp(1284352323.123)::VARCHAR AS utc_time;

.print *********************************************
.print strftime() with format string that mimics ::VARCHAR, respects TimeZone for both interfaces
-- RESULT:utc_time
-- RESULT:2010-09-13 04:32:03.123000+00
SELECT strftime(to_timestamp(1284352323.123), '%Y-%m-%d %H:%M:%S.%f%z') as utc_time;
