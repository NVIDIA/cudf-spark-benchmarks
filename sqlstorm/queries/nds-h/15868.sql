SELECT p_name, SUM(ps_supplycost) AS total_supply_cost
FROM part
JOIN partsupp ON p_partkey = ps_partkey
GROUP BY p_name
ORDER BY total_supply_cost DESC
LIMIT 10;
