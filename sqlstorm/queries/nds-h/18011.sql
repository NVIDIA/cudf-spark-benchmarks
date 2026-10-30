SELECT p.p_name, SUM(l.l_quantity) AS total_quantity
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
WHERE n.n_name = 'FRANCE'
GROUP BY p.p_name
ORDER BY total_quantity DESC
LIMIT 10;
