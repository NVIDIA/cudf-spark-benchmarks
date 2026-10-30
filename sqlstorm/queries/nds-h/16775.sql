SELECT p_brand, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
WHERE l_shipdate >= '1996-01-01' AND l_shipdate < '1996-02-01'
GROUP BY p_brand
ORDER BY revenue DESC;