SELECT o_orderkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM orders
JOIN lineitem ON o_orderkey = l_orderkey
GROUP BY o_orderkey
ORDER BY revenue DESC
LIMIT 10;
