.echo on
-- .timer on
.conn duckdb

.print '[[__DATAFOLDER__]]'
.print '[[__DBTAFOLDER__]]'

PRAGMA version;

-- https://duckdb.org/community_extensions/extensions/webbed.html
INSTALL webbed FROM community;
LOAD webbed;

SELECT extension_name,loaded,installed,install_path FROM duckdb_extensions() where installed = true;

-- Read XML files directly into tables
-- RESULT:name,skills
-- RESULT:Alice,[Python, SQL]
-- RESULT:Bob,[Java, React]
SELECT * FROM '[[__DATAFOLDER__]]\webbedData\simple_nested.xml';

-- RESULT:employee_id,employee_department,employee_active,name,performance_rating,email,salary,hire_date
-- RESULT:1001,Engineering,true,Alice Johnson,4.8,alice@company.com,95000,20200315120000
-- RESULT:1002,Marketing,true,Bob Smith,4.2,bob@company.com,75000,20210601120000
-- RESULT:1003,Sales,false,Carol Davis,3.9,carol@company.com,68000,20190110120000
SELECT * FROM read_xml('[[__DATAFOLDER__]]\webbedData\employee*.xml');

-- Parse and extract from XML content using XPath
-- RESULT:result
-- RESULT:Database Guide
SELECT xml_extract_text('<book><title>Database Guide</title></book>', '//title') as result;

-- Parse and extract from HTML content
-- RESULT:result
-- RESULT:Welcome
SELECT html_extract_text('<html><body><h1>Welcome</h1></body></html>', '//h1') as result;

-- Extract HTML tables directly into DuckDB
-- RESULT:table_index,row_index,columns
-- RESULT:0,0,[Name, Age]
-- RESULT:0,1,[John, 25]
SELECT * FROM html_extract_tables('<table><tr><th>Name</th><th>Age</th></tr><tr><td>John</td><td>25</td></tr></table>');

-- Extract links and images from HTML pages
-- RESULT:html_extract_links('<a href="https://example.com">Click here</a>')
-- RESULT:[{'text': Click here, 'href': 'https://example.com', 'title': NULL, 'line_number': 1}]
SELECT html_extract_links('<a href="https://example.com">Click here</a>');

-- RESULT:html_extract_images('<img src="photo.jpg" alt="Photo" width="800">')
-- RESULT:[{'alt': Photo, 'src': photo.jpg, 'title': NULL, 'width': 800, 'height': 48, 'line_number': 1}]
SELECT html_extract_images('<img src="photo.jpg" alt="Photo" width="800">');

-- Convert between XML and JSON formats
-- RESULT:result
-- RESULT:{"person":{"age":{"#text":"30"},"name":{"#text":"John"}}}
SELECT xml_to_json('<person><name>John</name><age>30</age></person>') as result;

-- has embedded carriage return so result compare does not work
-- result should look something like
-- [result<?xml version="1.0" encoding="UTF-8"?>
-- <root><age>30</age><name>John</name></root>]
SELECT json_to_xml('{"name":"John","age":"30"}') as result;


