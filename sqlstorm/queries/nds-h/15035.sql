SELECT n_name, COUNT(DISTINCT c_custkey) AS customer_count
FROM nation
JOIN supplier ON n_nationkey = s_nationkey
JOIN partsupp ON s_suppkey = ps_suppkey
JOIN part ON ps_partkey = p_partkey
JOIN lineitem ON p_partkey = l_partkey
JOIN orders ON l_orderkey = o_orderkey
JOIN customer ON o_custkey = c_custkey
GROUP BY n_name
ORDER BY customer_count DESC;
