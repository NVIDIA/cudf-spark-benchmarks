SELECT o_orderkey, SUM(l_extendedprice) AS total_revenue
FROM orders
JOIN lineitem ON orders.o_orderkey = lineitem.l_orderkey
GROUP BY o_orderkey
ORDER BY total_revenue DESC
LIMIT 10;
