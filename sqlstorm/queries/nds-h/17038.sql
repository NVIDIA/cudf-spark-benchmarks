SELECT s_name, COUNT(*) AS num_parts
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY s_name
ORDER BY num_parts DESC;
