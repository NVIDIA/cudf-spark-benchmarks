SELECT l_returnflag, l_linestatus, SUM(l_quantity) AS total_quantity, SUM(l_extendedprice) AS total_extended_price
FROM lineitem
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;