SELECT 
    COUNT(*) AS total_orders,
    SUM(o_totalprice) AS total_revenue,
    AVG(o_totalprice) AS avg_order_value,
    o_orderstatus,
    o_orderdate
FROM 
    orders
WHERE 
    o_orderdate >= '1997-01-01'
GROUP BY 
    o_orderstatus, o_orderdate
ORDER BY 
    o_orderdate DESC;