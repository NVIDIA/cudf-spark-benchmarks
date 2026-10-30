SELECT p_partkey, SUM(ps_availqty) AS total_available
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
GROUP BY p_partkey
ORDER BY total_available DESC
LIMIT 10;
