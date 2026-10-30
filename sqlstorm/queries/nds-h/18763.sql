SELECT p.p_name, s.s_name, o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON l.l_partkey = p.p_partkey
GROUP BY p.p_name, s.s_name, o.o_orderkey
ORDER BY total_revenue DESC
LIMIT 10;
