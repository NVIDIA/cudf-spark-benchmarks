SELECT p_brand, SUM(ps_supplycost * ps_availqty) AS total_cost
FROM partsupp
JOIN part ON partsupp.ps_partkey = part.p_partkey
GROUP BY p_brand
ORDER BY total_cost DESC
LIMIT 10;
