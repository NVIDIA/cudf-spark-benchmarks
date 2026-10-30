SELECT COUNT(*) AS total_orders, AVG(o_totalprice) AS avg_order_price
FROM orders
JOIN lineitem ON orders.o_orderkey = lineitem.l_orderkey
GROUP BY orders.o_orderstatus
ORDER BY total_orders DESC;
