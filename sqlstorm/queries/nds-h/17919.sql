SELECT l_returnflag, l_linestatus, SUM(l_quantity) AS sum_quantity, SUM(l_extendedprice) AS sum_extended_price
FROM lineitem
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;
