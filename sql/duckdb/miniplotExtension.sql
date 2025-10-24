-- https://duckdb.org/community_extensions/extensions/miniplot

.echo on
-- .timer on
.conn duckdb

.print dbfolder [[__DBFOLDER__]]
.print datafolder [[__DATAFOLDER__]]

-- remove database to start fresh
-- .system del /Q [[__DBFOLDER__]]\joined.geojsonseq > nul 2>&1

-- FORCE INSTALL miniplot from '.\local_extensions';
INSTALL miniplot FROM community;
LOAD miniplot;

-- Bar chart example
SELECT bar_chart(
    LIST_VALUE('Q1', 'Q2', 'Q3', 'Q4'),
    LIST_VALUE(100.0, 150.0, 200.0, 180.0),
    'Quarterly Sales'
);

-- Line chart example
SELECT line_chart(
    LIST_VALUE('Mon', 'Tue', 'Wed', 'Thu', 'Fri'),
    LIST_VALUE(5000.0, 6500.0, 4800.0, 7200.0, 8500.0),
    'Weekly Revenue Trend'
);

-- Scatter plot example
SELECT scatter_chart(
    LIST_VALUE(1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0),
    LIST_VALUE(10.0, 25.0, 30.0, 45.0, 60.0, 75.0, 85.0, 95.0),
    'Performance vs Time'
);

-- Area chart example
SELECT area_chart(
    LIST_VALUE('Jan', 'Feb', 'Mar', 'Apr', 'May'),
    LIST_VALUE(1000.0, 1500.0, 1200.0, 1800.0, 2100.0),
    'Monthly Growth'
);
