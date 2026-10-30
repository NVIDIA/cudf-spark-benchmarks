SELECT p_partkey, SUM(l_extendedprice) AS total_revenue
FROM part
JOIN lineitem ON p_partkey = l_partkey
GROUP BY p_partkey
ORDER BY total_revenue DESC
LIMIT 10;
