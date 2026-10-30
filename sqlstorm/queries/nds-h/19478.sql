SELECT ps.ps_partkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY ps.ps_partkey
ORDER BY total_cost DESC
LIMIT 10;
