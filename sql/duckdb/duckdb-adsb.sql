.echo on
.timer on
.conn duckdb

.print
.print -----------------------------------------------------
.print to run adsb you need to do some setup first...
.print -----------------------------------------------------
.print

-- comment .next to run this file 
.next

PRAGMA version;

-- get the data files from https://github.com/adsblol/globe_history_2026/releases/latest
-- mkdir -p output && cat v2026.04.08-planes-readsb-prod-0.tar.* | tar -xf - -C output
-- files are in ./output/traces/[two digit hex]

-- Unnest the trace array and map indices to field names
-- duckdb json is 1 based indexing
CREATE OR REPLACE TABLE aircraft_history AS 
SELECT 
    icao,
    timezone('Etc/UTC',to_timestamp(timestamp+t[1]::DOUBLE)) as t,
    t[2] AS lat,
    t[3] AS lon,
    t[4] AS alt,
    t[5] AS ground_speed,
    t[6] AS track
FROM (
    SELECT 
        icao,
        timestamp, 
        unnest(trace) AS t 
    FROM read_json(
        'G:/csharp_DotNet8_ODBC/data/adsb/2026.04.08/output/traces/*/*.json', 
        compression='gzip',
        maximum_sample_files=128
    )
);

SELECT count(*) FROM aircraft_history;

SELECT version,timestamp FROM aircraft_history;

