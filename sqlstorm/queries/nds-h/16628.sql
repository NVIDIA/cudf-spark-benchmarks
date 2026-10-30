SELECT p_brand, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM part
JOIN lineitem ON part.p_partkey = lineitem.l_partkey
WHERE lineitem.l_shipdate >= '1997-01-01' AND lineitem.l_shipdate < '1997-02-01'
GROUP BY p_brand
ORDER BY revenue DESC;