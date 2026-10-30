SELECT s.s_name, COUNT(o.o_orderkey) AS order_count
FROM supplier s
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
GROUP BY s.s_name
ORDER BY order_count DESC;
