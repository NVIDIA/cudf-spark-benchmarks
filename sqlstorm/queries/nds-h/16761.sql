SELECT n_name, SUM(l_extendedprice) AS total_revenue
FROM nation
JOIN supplier ON n_nationkey = s_nationkey
JOIN partsupp ON s_suppkey = ps_suppkey
JOIN lineitem ON ps_partkey = l_partkey
JOIN orders ON l_orderkey = o_orderkey
WHERE o_orderstatus = 'F'
GROUP BY n_name
ORDER BY total_revenue DESC;
