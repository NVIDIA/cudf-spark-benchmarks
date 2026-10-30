SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
JOIN orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY p_name
ORDER BY revenue DESC
LIMIT 10;