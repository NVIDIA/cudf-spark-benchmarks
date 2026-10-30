SELECT 
    c.c_name AS customer_name,
    SUM(o.o_totalprice) AS total_spent,
    COUNT(o.o_orderkey) AS total_orders,
    AVG(l.l_extendedprice) AS avg_item_price,
    SUM(l.l_quantity) AS total_quantity
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    o.o_orderstatus = 'O'
GROUP BY 
    c.c_name
ORDER BY 
    total_spent DESC
LIMIT 10;
