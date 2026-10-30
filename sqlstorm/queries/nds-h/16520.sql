SELECT p_name, SUM(l_extendedprice) AS total_sales
FROM part
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
GROUP BY p_name
ORDER BY total_sales DESC
LIMIT 10;
