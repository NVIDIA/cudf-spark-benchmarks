SELECT p_brand, SUM(l_extendedprice) as total_revenue
FROM part
JOIN partsupp ON p_partkey = ps_partkey
JOIN lineitem ON ps_suppkey = l_suppkey
GROUP BY p_brand
ORDER BY total_revenue DESC
LIMIT 10;
