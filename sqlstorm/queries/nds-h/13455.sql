SELECT 
    l_shipmode,
    COUNT(*) AS order_count,
    SUM(l_extendedprice) AS total_revenue,
    AVG(l_discount) AS average_discount
FROM 
    lineitem
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE 
    orders.o_orderdate >= '1997-01-01' AND orders.o_orderdate < '1997-12-31'
GROUP BY 
    l_shipmode
ORDER BY 
    total_revenue DESC;