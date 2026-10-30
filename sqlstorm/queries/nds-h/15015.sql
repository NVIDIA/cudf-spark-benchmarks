
SELECT p_partkey, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
GROUP BY p_partkey
ORDER BY revenue DESC
LIMIT 10;
