SELECT p_name, SUM(ps_availqty) AS total_available_quantity
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
GROUP BY p_name
ORDER BY total_available_quantity DESC
LIMIT 10;
