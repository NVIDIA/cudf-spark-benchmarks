SELECT p_name, SUM(l_extendedprice) AS total_revenue
FROM lineitem
JOIN part ON lineitem.l_partkey = part.p_partkey
GROUP BY p_name
ORDER BY total_revenue DESC
LIMIT 10;
