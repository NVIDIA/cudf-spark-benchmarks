SELECT p_name, SUM(l_extendedprice) AS total_revenue
FROM part
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
WHERE l_shipdate >= '1997-01-01'
GROUP BY p_name
ORDER BY total_revenue DESC
LIMIT 10;