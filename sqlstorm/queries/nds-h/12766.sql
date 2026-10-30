SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
WHERE l.l_shipdate >= DATE '1994-01-01' AND l.l_shipdate < DATE '1995-01-01'
GROUP BY o.o_orderkey
ORDER BY revenue DESC
LIMIT 10;
