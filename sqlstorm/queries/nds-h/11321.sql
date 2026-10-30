SELECT p.p_name, s.s_name, SUM(ps.ps_availqty) AS total_available
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE r.r_name = 'ASIA'
GROUP BY p.p_name, s.s_name
ORDER BY total_available DESC
LIMIT 100;