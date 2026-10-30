SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM part
JOIN partsupp ON p_partkey = ps_partkey
JOIN lineitem ON ps_suppkey = l_suppkey
JOIN orders ON l_orderkey = o_orderkey
WHERE o_orderdate >= '1997-01-01'
GROUP BY p_name
ORDER BY total_revenue DESC
LIMIT 10;