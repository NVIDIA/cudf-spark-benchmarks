SELECT p_brand, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM part p
JOIN lineitem l ON p.p_partkey = l.l_partkey
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
GROUP BY p_brand
ORDER BY total_revenue DESC;