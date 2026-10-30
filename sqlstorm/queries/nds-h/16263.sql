SELECT p_partkey, p_name, p_mfgr, SUM(ps_supplycost) AS total_supplycost
FROM part
JOIN partsupp ON part.p_partkey = partsupp.ps_partkey
GROUP BY p_partkey, p_name, p_mfgr
ORDER BY total_supplycost DESC
LIMIT 10;
