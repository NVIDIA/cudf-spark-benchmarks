SELECT COUNT(*), AVG(l_extendedprice), SUM(l_discount)
FROM lineitem
WHERE l_shipdate >= '1995-01-01' AND l_shipdate < '1996-01-01'
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;
