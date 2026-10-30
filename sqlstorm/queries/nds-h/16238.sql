SELECT r_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM region
JOIN nation ON r_regionkey = n_regionkey
JOIN supplier ON n_nationkey = s_nationkey
JOIN partsupp ON s_suppkey = ps_suppkey
JOIN part ON ps_partkey = p_partkey
JOIN lineitem ON p_partkey = l_partkey
JOIN orders ON l_orderkey = o_orderkey
GROUP BY r_name
ORDER BY revenue DESC;
