SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM part
JOIN lineitem ON p_partkey = l_partkey
GROUP BY p_name
ORDER BY total_revenue DESC
LIMIT 10;
