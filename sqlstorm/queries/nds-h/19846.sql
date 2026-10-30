SELECT p.p_name, SUM(l.l_extendedprice) AS total_sales
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN lineitem l ON ps.ps_suppkey = l.l_suppkey
GROUP BY p.p_name
ORDER BY total_sales DESC
LIMIT 10;
