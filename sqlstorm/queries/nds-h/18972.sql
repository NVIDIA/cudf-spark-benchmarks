SELECT p.p_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM lineitem l
JOIN part p ON l.l_partkey = p.p_partkey
WHERE l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1998-01-01'
GROUP BY p.p_name
ORDER BY total_revenue DESC
LIMIT 10;