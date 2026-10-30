SELECT 
    COUNT(*) AS total_orders, 
    SUM(o_totalprice) AS total_revenue, 
    AVG(o_totalprice) AS avg_order_value
FROM 
    orders 
WHERE 
    o_orderdate BETWEEN '1996-01-01' AND '1996-12-31';