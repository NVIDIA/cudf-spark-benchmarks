SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON p_partkey = l_partkey
JOIN orders ON l_orderkey = o_orderkey
WHERE o_orderdate >= '1997-01-01' AND o_orderdate < '1998-01-01'
GROUP BY p_name
ORDER BY revenue DESC
LIMIT 10;