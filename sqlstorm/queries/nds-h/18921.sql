SELECT p_brand, SUM(l_extendedprice) AS total_revenue 
FROM part p 
JOIN lineitem l ON p.p_partkey = l.l_partkey 
GROUP BY p_brand 
ORDER BY total_revenue DESC 
LIMIT 5;
