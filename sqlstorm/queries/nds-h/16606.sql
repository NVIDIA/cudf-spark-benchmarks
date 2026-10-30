SELECT l_returnflag, l_linestatus, SUM(l_quantity) AS sum_quantity, SUM(l_extendedprice) AS sum_extended_price
FROM lineitem
WHERE l_shipdate >= '1997-01-01'
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;