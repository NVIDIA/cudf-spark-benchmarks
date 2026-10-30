SELECT l_returnflag, l_linestatus, COUNT(*) AS cnt
FROM lineitem
WHERE l_shipdate >= '1997-01-01'
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;