SELECT s.s_name, COUNT(DISTINCT ps.ps_partkey) AS parts_supplied
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY s.s_name
ORDER BY parts_supplied DESC
LIMIT 10;
