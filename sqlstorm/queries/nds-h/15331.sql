SELECT p_brand, COUNT(*) AS number_of_suppliers
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
JOIN supplier ON partsupp.ps_suppkey = supplier.s_suppkey
GROUP BY p_brand
ORDER BY number_of_suppliers DESC
LIMIT 10;
