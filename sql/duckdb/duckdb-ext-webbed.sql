.echo on
-- .timer on
.conn duckdb

.print '[[__DATAFOLDER__]]'
.print '[[__DBTAFOLDER__]]'

PRAGMA version;

-- https://duckdb.org/community_extensions/extensions/webbed.html
-- FORCE INSTALL webbed from '.\extensions\duckdb';
INSTALL webbed FROM community;
LOAD webbed;

SELECT extension_name,loaded,installed,install_path FROM duckdb_extensions() where installed = true;

-- RESULT:username,gender,password,frstname,position,lastname,email,salary,contact
-- RESULT:BarryAllen,Male,barry123,Barry,Frontend Developer,Allen,barryallen@gmail.com,7.5lpa,+91 7834918230
-- RESULT:JohnDoe,Male,johndoe123,John,Marketing Manager,Doe,johndoe@example.com,12lpa,+91 9934671209
-- RESULT:BobJohnson,Male,bob123,Bob,Software Engineer,Johnson,bob.johnson@example.com,9lpa,+91 7722012983
-- RESULT:Akash123,Male,akash123,Akash,Software Developer,Mete,akashmete129@gmail.com,9.5lpa,+91 7051794388
-- RESULT:JaneSmith,Female,janesmith456,Jane,Human Resources Manager,Smith,janesmith@example.com,10lpa,+91 9091293801
-- RESULT:AlexWest,Female,alex123,Alex,Software Developer,West,alex123@gmail.com,8.5lpa,+91 9335784511
SELECT * FROM read_xml('[[__DATAFOLDER__]]\webbedData\employee.xml') order by lastname, frstname;

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


