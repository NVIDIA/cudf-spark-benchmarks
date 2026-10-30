SELECT 
    o_orderkey, 
    COUNT(l_linenumber) AS line_count, 
    SUM(l_quantity) AS total_quantity, 
    SUM(l_extendedprice) AS total_price
FROM 
    orders 
JOIN 
    lineitem ON orders.o_orderkey = lineitem.l_orderkey
GROUP BY 
    o_orderkey
ORDER BY 
    total_price DESC
LIMIT 10;
