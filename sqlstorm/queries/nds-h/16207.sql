SELECT p_brand, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM part
JOIN lineitem ON p_partkey = l_partkey
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1997-12-31'
GROUP BY p_brand
ORDER BY total_revenue DESC
LIMIT 10;