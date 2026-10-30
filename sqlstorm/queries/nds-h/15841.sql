SELECT p_brand, AVG(ps_supplycost) AS avg_supplycost
FROM partsupp
JOIN part ON partsupp.ps_partkey = part.p_partkey
GROUP BY p_brand
ORDER BY avg_supplycost DESC;
