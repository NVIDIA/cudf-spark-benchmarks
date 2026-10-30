SELECT s.s_name, COUNT(*) AS total_parts, SUM(ps.ps_supplycost) AS total_supply_cost 
FROM supplier s 
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN part p ON ps.ps_partkey = p.p_partkey 
GROUP BY s.s_name 
ORDER BY total_parts DESC 
LIMIT 10;