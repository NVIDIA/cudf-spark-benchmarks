SELECT 
    COUNT(*) AS total_orders,
    SUM(o_totalprice) AS total_revenue,
    AVG(o_totalprice) AS average_order_value,
    MAX(o_orderdate) AS last_order_date,
    MIN(o_orderdate) AS first_order_date
FROM 
    orders
WHERE 
    o_orderdate BETWEEN '1997-01-01' AND '1997-12-31';