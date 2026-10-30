SELECT p.p_name, SUM(l.l_extendedprice) AS total_revenue
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN supplier s ON l.l_suppkey = s.s_suppkey
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
GROUP BY p.p_name
ORDER BY total_revenue DESC
LIMIT 10;
