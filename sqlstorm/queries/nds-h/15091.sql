SELECT p.p_name, SUM(ps.ps_supplycost) AS total_supplycost
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
GROUP BY p.p_name
ORDER BY total_supplycost DESC
LIMIT 10;
