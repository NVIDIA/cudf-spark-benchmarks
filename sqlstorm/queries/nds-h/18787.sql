SELECT p_brand, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON p_partkey = l_partkey
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1997-04-01'
GROUP BY p_brand
ORDER BY revenue DESC
LIMIT 10;