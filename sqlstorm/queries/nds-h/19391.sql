SELECT ps.ps_partkey, SUM(ps.ps_supplycost) AS total_supply_cost
FROM partsupp ps
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY ps.ps_partkey
ORDER BY total_supply_cost DESC
LIMIT 10;
