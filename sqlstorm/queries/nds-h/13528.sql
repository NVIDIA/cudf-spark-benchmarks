SELECT 
    o_orderpriority, 
    COUNT(*) as order_count, 
    SUM(o_totalprice) as total_revenue 
FROM 
    orders 
WHERE 
    o_orderdate >= '1997-01-01' 
    AND o_orderdate < '1998-01-01' 
GROUP BY 
    o_orderpriority 
ORDER BY 
    total_revenue DESC;