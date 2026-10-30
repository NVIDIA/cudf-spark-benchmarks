SELECT p.p_brand, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
GROUP BY p.p_brand
ORDER BY revenue DESC;
