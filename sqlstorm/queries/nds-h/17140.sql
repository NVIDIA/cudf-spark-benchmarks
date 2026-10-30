SELECT p_brand, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue 
FROM part 
JOIN lineitem ON part.p_partkey = lineitem.l_partkey 
GROUP BY p_brand 
ORDER BY total_revenue DESC 
LIMIT 10;
