SELECT p_brand, SUM(l_quantity) AS total_quantity
FROM part
JOIN lineitem ON p_partkey = l_partkey
GROUP BY p_brand
ORDER BY total_quantity DESC
LIMIT 10;
