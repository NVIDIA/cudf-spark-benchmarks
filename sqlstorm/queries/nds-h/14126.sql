SELECT n_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM nation
JOIN supplier ON n_nationkey = s_nationkey
JOIN partsupp ON s_suppkey = ps_suppkey
JOIN part ON ps_partkey = p_partkey
JOIN lineitem ON p_partkey = l_partkey
JOIN orders ON l_orderkey = o_orderkey
WHERE o_orderdate >= DATE '1997-01-01' AND o_orderdate < DATE '1997-10-01'
GROUP BY n_name
ORDER BY revenue DESC;