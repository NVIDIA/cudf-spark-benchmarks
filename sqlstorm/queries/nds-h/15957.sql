SELECT p_name, SUM(l_extendedprice) AS total_revenue
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
GROUP BY p_name
ORDER BY total_revenue DESC
LIMIT 10;
