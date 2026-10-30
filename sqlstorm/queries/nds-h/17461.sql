SELECT l_returnflag, l_linestatus, SUM(l_quantity) AS sum_quantity
FROM lineitem
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;
