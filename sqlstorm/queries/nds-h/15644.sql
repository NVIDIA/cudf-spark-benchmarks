SELECT l_returnflag, l_linestatus, SUM(l_quantity) AS sum_quantity, SUM(l_extendedprice) AS sum_extendedprice
FROM lineitem
WHERE l_shipdate >= '1997-01-01' AND l_shipdate <= '1997-12-31'
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;