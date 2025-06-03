-- https://duckdb.org/docs/stable/core_extensions/full_text_search

.echo on
.timer on

INSTALL fts;
LOAD fts;

CREATE OR REPLACE TABLE documents (
    document_identifier VARCHAR,
    text_content VARCHAR,
    author VARCHAR,
    doc_version INTEGER
);

INSERT INTO documents
    VALUES ('doc1',
            'The mallard is a dabbling duck that breeds throughout the temperate.',
            'Hannes Mühleisen',
            3),
           ('doc2',
            'The cat is a domestic species of small carnivorous mammal.',
            'Laurens Kuiper',
            2
           );


PRAGMA create_fts_index(
    'documents', 'document_identifier', 'text_content', 'author', overwrite = 1
);

-- RESULT:document_identifier,text_content,score
-- RESULT:doc1,The mallard is a dabbling duck that breeds throughout the temperate.,0.3094700890003546
SELECT document_identifier, text_content, score
FROM (
    SELECT *, fts_main_documents.match_bm25(
        document_identifier,
        'Muhleisen',
        fields := 'author'
    ) AS score
    FROM documents
) sq
WHERE score IS NOT NULL
  AND doc_version > 2
ORDER BY score DESC;

-- RESULT:document_identifier,text_content,score
-- RESULT:doc2,The cat is a domestic species of small carnivorous mammal.,0.5860760977528838
SELECT document_identifier, text_content, score
FROM (
    SELECT *, fts_main_documents.match_bm25(
        document_identifier,
        'small cats'
    ) AS score
    FROM documents
) sq
WHERE score IS NOT NULL
ORDER BY score DESC;


