SELECT 
    COUNT(*) AS total_orders, 
    SUM(o_totalprice) AS total_revenue 
FROM 
    orders 
WHERE 
    o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND o_orderstatus = 'O';