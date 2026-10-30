SELECT s_name, COUNT(*) AS supply_count
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY s_name
ORDER BY supply_count DESC
LIMIT 10;
