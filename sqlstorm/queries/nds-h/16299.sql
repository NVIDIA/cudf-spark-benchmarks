SELECT s_name, COUNT(o_orderkey) AS total_orders
FROM supplier
JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
JOIN lineitem ON partsupp.ps_partkey = lineitem.l_partkey
JOIN orders ON lineitem.l_orderkey = orders.o_orderkey
GROUP BY s_name
ORDER BY total_orders DESC
LIMIT 10;
