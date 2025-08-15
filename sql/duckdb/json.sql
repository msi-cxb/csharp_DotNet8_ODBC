-- https://duckdb.org/docs/stable/data/json/creating_json

-- .echo on
-- .timer on
.conn duckdb

-- RESULT:v
-- RESULT:42
SELECT '{"d[u]._\"ck":42}'->'$."d[u]._\"ck"' AS v;

CREATE OR REPLACE TABLE example (j JSON);

DROP TABLE IF EXISTS example;
CREATE TABLE example (j JSON);
INSERT INTO example VALUES('{ "family": "anatidae", "species": [ "duck", "goose", "swan", null ] }');

-- RESULT:family
-- RESULT:"anatidae"
SELECT j.family FROM example;

-- RESULT:(j -> '$.family')
-- RESULT:"anatidae"
SELECT j->'$.family' FROM example;

-- RESULT:"json"(j)
-- RESULT:{"family":"anatidae","species":["duck","goose","swan",null]}
SELECT json(j) FROM example;

-- RESULT:json_valid(j)
-- RESULT:true
SELECT json_valid(j) FROM example;

-- RESULT:json_valid('{')
-- RESULT:false
SELECT json_valid('{') FROM example;

-- RESULT:json_array_length('["duck","goose","swan",null]')
-- RESULT:4
SELECT json_array_length('["duck","goose","swan",null]');

-- RESULT:json_array_length(j, 'species')
-- RESULT:4
SELECT json_array_length(j, 'species') FROM example;

-- RESULT:json_array_length(j, '/species')
-- RESULT:4
SELECT json_array_length(j, '/species') FROM example;

-- RESULT:json_array_length(j, '$.species')
-- RESULT:4
SELECT json_array_length(j, '$.species') FROM example;

-- RESULT:json_array_length(j, main.list_value('$.species'))
-- RESULT:[4]
SELECT json_array_length(j, ['$.species']) FROM example;

-- RESULT:json_type(j)
-- RESULT:OBJECT
SELECT json_type(j) FROM example;

-- RESULT:json_keys(j)
-- RESULT:[family, species]
SELECT json_keys(j) FROM example;

-- RESULT:json_structure(j)
-- RESULT:{"family":"VARCHAR","species":["VARCHAR"]}
SELECT json_structure(j) FROM example;

-- RESULT:json_structure('["duck",{"family":"anatidae"}]')
-- RESULT:["JSON"]
SELECT json_structure('["duck",{"family":"anatidae"}]');

-- RESULT:json_contains('{"key":"value"}', '"value"')
-- RESULT:true
SELECT json_contains('{"key":"value"}','"value"');

-- RESULT:json_contains('{"key":1}', '1')
-- RESULT:true
SELECT json_contains('{"key":1}','1');

-- RESULT:json_contains('{"top_key":{"key":"value"}}', '{"key":"value"}')
-- RESULT:true
SELECT json_contains('{"top_key":{"key":"value"}}','{"key":"value"}');

-- RESULT:json_extract(j, '$.family')
-- RESULT:"anatidae"
SELECT json_extract(j, '$.family') FROM example;

-- RESULT:(j -> '$.family')
-- RESULT:"anatidae"
SELECT j->'$.family' FROM example;

-- RESULT:(j -> '$.species[0]')
-- RESULT:"duck"
SELECT j->'$.species[0]' FROM example;

-- RESULT:(j -> '$.species[*]')
-- RESULT:['"duck"', '"goose"', '"swan"', 'null']
SELECT j->'$.species[*]' FROM example;

-- RESULT:(j ->> '$.species[*]')
-- RESULT:[duck, goose, swan, NULL]
SELECT j->>'$.species[*]' FROM example;

SELECT j->'$.species'->0 FROM example;

SELECT j->'species'->['0','1'] FROM example;

-- RESULT:json_extract_string(j, '$.family')
-- RESULT:anatidae
SELECT json_extract_string(j, '$.family') FROM example;

-- RESULT:(j ->> '$.family')
-- RESULT:anatidae
SELECT j->>'$.family' FROM example;

-- RESULT:(j ->> '$.species[0]')
-- RESULT:duck
SELECT j->>'$.species[0]' FROM example;

-- RESULT:((j -> 'species') ->> 0)
-- RESULT:duck
SELECT j->'species'->>0 FROM example;

-- RESULT:((j -> 'species') ->> main.list_value('0', '1'))
-- RESULT:[NULL, NULL]
SELECT j->'species'->>['0','1'] FROM example;

-- RESULT:((j -> 'species') -> main.list_value('/0', '/1'))
-- RESULT:['"duck"', '"goose"']
SELECT j->'species'->['/0', '/1'] FROM example;

-- RESULT:((j -> 'species') ->> main.list_value('/0', '/1'))
-- RESULT:[duck, goose]
SELECT j->'species'->>['/0','/1'] FROM example;

-- RESULT:family,species
-- RESULT:"anatidae",["duck","goose","swan",null]
WITH extracted AS (
    SELECT json_extract(j, ['family', 'species']) AS extracted_list
    FROM example
)
SELECT
    extracted_list[1] AS family,
    extracted_list[2] AS species
FROM extracted;

CREATE OR REPLACE TABLE example1 (k VARCHAR, v INTEGER);

INSERT INTO example1 VALUES ('duck', 42), ('goose', 7);

-- RESULT:json_group_array(v)
-- RESULT:[42,7]
SELECT json_group_array(v) FROM example1;

-- RESULT:json_group_object(k, v)
-- RESULT:{"duck":42,"goose":7}
SELECT json_group_object(k, v) FROM example1;

CREATE OR REPLACE TABLE example2 (j JSON);

INSERT INTO example2 VALUES
    ('{"family": "anatidae", "species": ["duck", "goose"], "coolness": 42.42}'),
    ('{"family": "canidae", "species": ["labrador", "bulldog"], "hair": true}');

-- RESULT:json_group_structure(j)
-- RESULT:{"family":"VARCHAR","species":["VARCHAR"],"coolness":"DOUBLE","hair":"BOOLEAN"}
SELECT json_group_structure(j) FROM example2;

CREATE OR REPLACE TABLE example (j JSON);

INSERT INTO example VALUES
    ('{"family": "anatidae", "species": ["duck", "goose"], "coolness": 42.42}'),
    ('{"family": "canidae", "species": ["labrador", "bulldog"], "hair": true}');

-- RESULT:json_transform(j, '{"family": "VARCHAR", "coolness": "DOUBLE"}')
-- RESULT:{'family': anatidae, 'coolness': 42.42}
-- RESULT:{'family': canidae, 'coolness': NULL}
SELECT json_transform(j, '{"family": "VARCHAR", "coolness": "DOUBLE"}') FROM example;

-- RESULT:json_transform(j, '{"family": "TINYINT", "coolness": "DECIMAL(4, 2)"}')
-- RESULT:{'family': NULL, 'coolness': 42.42}
-- RESULT:{'family': NULL, 'coolness': NULL}
SELECT json_transform(j, '{"family": "TINYINT", "coolness": "DECIMAL(4, 2)"}') FROM example;

-- SELECT json_transform_strict(j, '{"family": "TINYINT", "coolness": "DOUBLE"}') FROM example;
-- Invalid Input Error: Failed to cast value: "anatidae"

CREATE OR REPLACE TABLE example (j JSON);

INSERT INTO example VALUES
    ('{"family": "anatidae", "species": ["duck", "goose"], "coolness": 42.42}'),
    ('{"family": "canidae", "species": ["labrador", "bulldog"], "hair": true}');

-- RESULT:key,value,type,atom,id,parent,fullkey,path,rowid
-- RESULT:family,"anatidae",VARCHAR,"anatidae",2,null,$.family,$,0
-- RESULT:species,["duck","goose"],ARRAY,null,4,null,$.species,$,1
-- RESULT:coolness,42.42,DOUBLE,42.42,8,null,$.coolness,$,2
-- RESULT:family,"canidae",VARCHAR,"canidae",2,null,$.family,$,0
-- RESULT:species,["labrador","bulldog"],ARRAY,null,4,null,$.species,$,1
-- RESULT:hair,true,BOOLEAN,true,8,null,$.hair,$,2
SELECT je.*, je.rowid
FROM example AS e, json_each(e.j) AS je;

-- RESULT:key,value,type,atom,id,parent,fullkey,path,rowid
-- RESULT:0,"duck",VARCHAR,"duck",5,null,$.species[0],$.species,0
-- RESULT:1,"goose",VARCHAR,"goose",6,null,$.species[1],$.species,1
-- RESULT:0,"labrador",VARCHAR,"labrador",5,null,$.species[0],$.species,0
-- RESULT:1,"bulldog",VARCHAR,"bulldog",6,null,$.species[1],$.species,1
SELECT je.*, je.rowid
FROM example AS e, json_each(e.j, '$.species') AS je;

-- RESULT:key,value,type,id,parent,fullkey,rowid
-- RESULT:null,{"family":"anatidae","species":["duck","goose"],"coolness":42.42},OBJECT,0,null,$,0
-- RESULT:family,"anatidae",VARCHAR,2,0,$.family,1
-- RESULT:species,["duck","goose"],ARRAY,4,0,$.species,2
-- RESULT:0,"duck",VARCHAR,5,4,$.species[0],3
-- RESULT:1,"goose",VARCHAR,6,4,$.species[1],4
-- RESULT:coolness,42.42,DOUBLE,8,0,$.coolness,5
-- RESULT:null,{"family":"canidae","species":["labrador","bulldog"],"hair":true},OBJECT,0,null,$,0
-- RESULT:family,"canidae",VARCHAR,2,0,$.family,1
-- RESULT:species,["labrador","bulldog"],ARRAY,4,0,$.species,2
-- RESULT:0,"labrador",VARCHAR,5,4,$.species[0],3
-- RESULT:1,"bulldog",VARCHAR,6,4,$.species[1],4
-- RESULT:hair,true,BOOLEAN,8,0,$.hair,5
SELECT je.key, je.value, je.type, je.id, je.parent, je.fullkey, je.rowid
FROM example AS e, json_tree(e.j) AS je;

DROP TABLE IF EXISTS example;
DROP TABLE IF EXISTS example1;
DROP TABLE IF EXISTS example2;
SHOW ALL TABLES;
