SELECT l_returnflag, l_linestatus, SUM(l_quantity) AS sum_qty, SUM(l_extendedprice) AS sum_base_price,
       AVG(l_discount) AS avg_discount, COUNT(*) AS count_order
FROM lineitem
WHERE l_shipdate >= '1997-01-01' AND l_shipdate < '1997-12-31'
GROUP BY l_returnflag, l_linestatus
ORDER BY l_returnflag, l_linestatus;