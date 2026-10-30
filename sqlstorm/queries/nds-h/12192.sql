SELECT 
    p.p_name, 
    SUM(l.l_quantity) AS total_quantity, 
    SUM(l.l_extendedprice) AS total_extended_price, 
    AVG(l.l_discount) AS average_discount, 
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
GROUP BY 
    p.p_name
ORDER BY 
    total_extended_price DESC
LIMIT 100;
