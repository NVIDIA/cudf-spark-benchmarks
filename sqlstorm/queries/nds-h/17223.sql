SELECT p.p_partkey, p.p_name, p.p_brand, SUM(l.l_quantity) AS total_quantity
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
GROUP BY p.p_partkey, p.p_name, p.p_brand
ORDER BY total_quantity DESC
LIMIT 10;
