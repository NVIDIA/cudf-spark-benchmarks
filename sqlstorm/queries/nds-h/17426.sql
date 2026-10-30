SELECT p_name, p_brand, SUM(ps_supplycost) AS total_supply_cost
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
GROUP BY p_name, p_brand
ORDER BY total_supply_cost DESC
LIMIT 10;
