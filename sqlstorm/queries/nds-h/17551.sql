SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM lineitem
JOIN part ON lineitem.l_partkey = part.p_partkey
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
GROUP BY p_name
ORDER BY total_revenue DESC
LIMIT 10;