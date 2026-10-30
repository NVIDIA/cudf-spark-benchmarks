SELECT 
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderstatus,
    o_orderpriority,
    l_shipmode
FROM 
    lineitem
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE 
    l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1997-12-31'
GROUP BY 
    l_orderkey, o_orderstatus, o_orderpriority, l_shipmode
ORDER BY 
    total_revenue DESC
LIMIT 10;