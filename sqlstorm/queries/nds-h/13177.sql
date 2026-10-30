SELECT 
    COUNT(DISTINCT o_orderkey) AS total_orders,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    AVG(l_quantity) AS avg_quantity_per_order,
    MAX(o_orderdate) AS latest_order_date
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderdate >= '1997-01-01'
    AND o.o_orderdate < '1998-01-01'
GROUP BY 
    o.o_orderstatus
ORDER BY 
    total_orders DESC;