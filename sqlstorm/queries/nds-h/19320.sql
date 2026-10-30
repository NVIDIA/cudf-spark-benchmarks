SELECT p_name, SUM(ps_supplycost) AS total_supply_cost
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
GROUP BY p_name
ORDER BY total_supply_cost DESC
LIMIT 10;
