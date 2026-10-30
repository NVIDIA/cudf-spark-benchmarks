SELECT s.s_name, COUNT(*) AS supply_count
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY s.s_name
ORDER BY supply_count DESC
LIMIT 10;
