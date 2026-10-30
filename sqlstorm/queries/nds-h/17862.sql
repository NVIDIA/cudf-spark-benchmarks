SELECT p_partkey, p_name, SUM(ps_availqty) AS total_availqty
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
GROUP BY p_partkey, p_name
ORDER BY total_availqty DESC
LIMIT 10;
