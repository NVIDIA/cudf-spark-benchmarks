SELECT n_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM nation
JOIN supplier ON n_nationkey = s_nationkey
JOIN partsupp ON s_suppkey = ps_suppkey
JOIN lineitem ON ps_partkey = l_partkey
JOIN orders ON l_orderkey = o_orderkey
WHERE o_orderdate >= '1997-01-01' AND o_orderdate < '1998-01-01'
GROUP BY n_name
ORDER BY revenue DESC;