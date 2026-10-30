SELECT p_name, SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM lineitem
JOIN part ON lineitem.l_partkey = part.p_partkey
WHERE l_shipdate >= DATE '1995-01-01' AND l_shipdate < DATE '1996-01-01'
GROUP BY p_name
ORDER BY revenue DESC
LIMIT 10;
