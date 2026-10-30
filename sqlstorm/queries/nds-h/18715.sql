SELECT s_name, COUNT(*) AS total_parts
FROM supplier
JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
JOIN part ON partsupp.ps_partkey = part.p_partkey
GROUP BY s_name
ORDER BY total_parts DESC
LIMIT 10;
