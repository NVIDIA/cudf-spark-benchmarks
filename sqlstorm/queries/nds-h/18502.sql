SELECT p_partkey, p_name, SUM(ps_supplycost) AS total_cost
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
GROUP BY p_partkey, p_name
ORDER BY total_cost DESC
LIMIT 10;
