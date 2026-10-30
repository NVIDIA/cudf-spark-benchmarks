SELECT p.p_brand, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM lineitem l
JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
GROUP BY p.p_brand
ORDER BY revenue DESC
LIMIT 10;
