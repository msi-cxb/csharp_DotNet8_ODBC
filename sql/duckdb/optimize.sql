-- https://15799.courses.cs.cmu.edu/spring2025/project1.html

.echo on
.timer on

-- https://duckdb.org/docs/stable/guides/meta/explain
-- https://duckdb.org/docs/stable/configuration/pragmas

-- SET explain_output = 'physical_only';
-- SET explain_output = 'optimized_only';
SET explain_output = 'all';

-- SET enable_profiling = 'no_output';
-- SET enable_profiling = 'json';
-- SET enable_profiling = 'query_tree';
SET enable_profiling = 'query_tree_optimizer';

-- SET profiling_mode = 'standard';
SET profiling_mode = 'detailed';


CREATE OR REPLACE TABLE foo (foo1 int, foo2 int);

INSERT INTO foo SELECT i, i+15799 from generate_series(1, 100000) AS t(i);

CREATE OR REPLACE TABLE bar (bar1 int, bar2 int);

INSERT INTO bar SELECT i, i+15799 FROM generate_series(1, 100000) AS t(i);

ANALYZE;

EXPLAIN SELECT foo1, bar2 FROM foo, bar WHERE foo1 = bar1 and foo1 < 50 and bar2 > 25;

-- RESULT:foo1,bar2
-- RESULT:1,15800
-- RESULT:2,15801
-- RESULT:3,15802
-- RESULT:4,15803
-- RESULT:5,15804
-- RESULT:6,15805
-- RESULT:7,15806
-- RESULT:8,15807
-- RESULT:9,15808
-- RESULT:10,15809
-- RESULT:11,15810
-- RESULT:12,15811
-- RESULT:13,15812
-- RESULT:14,15813
-- RESULT:15,15814
-- RESULT:16,15815
-- RESULT:17,15816
-- RESULT:18,15817
-- RESULT:19,15818
-- RESULT:20,15819
-- RESULT:21,15820
-- RESULT:22,15821
-- RESULT:23,15822
-- RESULT:24,15823
-- RESULT:25,15824
-- RESULT:26,15825
-- RESULT:27,15826
-- RESULT:28,15827
-- RESULT:29,15828
-- RESULT:30,15829
-- RESULT:31,15830
-- RESULT:32,15831
-- RESULT:33,15832
-- RESULT:34,15833
-- RESULT:35,15834
-- RESULT:36,15835
-- RESULT:37,15836
-- RESULT:38,15837
-- RESULT:39,15838
-- RESULT:40,15839
-- RESULT:41,15840
-- RESULT:42,15841
-- RESULT:43,15842
-- RESULT:44,15843
-- RESULT:45,15844
-- RESULT:46,15845
-- RESULT:47,15846
-- RESULT:48,15847
-- RESULT:49,15848
SELECT foo1, bar2 FROM foo, bar WHERE foo1 = bar1 and foo1 < 50 and bar2 > 25;

PRAGMA disable_optimizer;

EXPLAIN SELECT foo1, bar2 FROM foo, bar WHERE foo1 = bar1 and foo1 < 50 and bar2 > 25;

-- RESULT:foo1,bar2
-- RESULT:1,15800
-- RESULT:2,15801
-- RESULT:3,15802
-- RESULT:4,15803
-- RESULT:5,15804
-- RESULT:6,15805
-- RESULT:7,15806
-- RESULT:8,15807
-- RESULT:9,15808
-- RESULT:10,15809
-- RESULT:11,15810
-- RESULT:12,15811
-- RESULT:13,15812
-- RESULT:14,15813
-- RESULT:15,15814
-- RESULT:16,15815
-- RESULT:17,15816
-- RESULT:18,15817
-- RESULT:19,15818
-- RESULT:20,15819
-- RESULT:21,15820
-- RESULT:22,15821
-- RESULT:23,15822
-- RESULT:24,15823
-- RESULT:25,15824
-- RESULT:26,15825
-- RESULT:27,15826
-- RESULT:28,15827
-- RESULT:29,15828
-- RESULT:30,15829
-- RESULT:31,15830
-- RESULT:32,15831
-- RESULT:33,15832
-- RESULT:34,15833
-- RESULT:35,15834
-- RESULT:36,15835
-- RESULT:37,15836
-- RESULT:38,15837
-- RESULT:39,15838
-- RESULT:40,15839
-- RESULT:41,15840
-- RESULT:42,15841
-- RESULT:43,15842
-- RESULT:44,15843
-- RESULT:45,15844
-- RESULT:46,15845
-- RESULT:47,15846
-- RESULT:48,15847
-- RESULT:49,15848
SELECT foo1, bar2 FROM foo, bar WHERE foo1 = bar1 and foo1 < 50 and bar2 > 25;

SET enable_profiling = 'no_output';

PRAGMA enable_optimizer;

SELECT foo1, bar2 FROM foo, bar WHERE foo1 = bar1 and foo1 < 50 and bar2 > 25;
