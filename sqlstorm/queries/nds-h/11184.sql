SELECT p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM lineitem l
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY p.p_name
ORDER BY total_revenue DESC
LIMIT 10;
