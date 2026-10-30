SELECT p_brand, SUM(ps_supplycost) AS total_supplycost
FROM partsupp
JOIN part ON partsupp.ps_partkey = part.p_partkey
GROUP BY p_brand
ORDER BY total_supplycost DESC
LIMIT 10;
