SELECT n_name, SUM(l_extendedprice * (1 - l_discount)) AS total_sales
FROM nation
JOIN supplier ON n_nationkey = s_nationkey
JOIN partsupp ON s_suppkey = ps_suppkey
JOIN lineitem ON ps_partkey = l_partkey
GROUP BY n_name
ORDER BY total_sales DESC;
