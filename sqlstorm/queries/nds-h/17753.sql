SELECT p_brand, COUNT(*) AS supplier_count, SUM(ps_supplycost * ps_availqty) AS total_supplycost
FROM part
JOIN partsupp ON p_partkey = ps_partkey
JOIN supplier ON ps_suppkey = s_suppkey
GROUP BY p_brand
ORDER BY supplier_count DESC;
