SELECT 
    p_brand,
    AVG(l_extendedprice) AS avg_price,
    SUM(l_quantity) AS total_quantity,
    COUNT(DISTINCT o_orderkey) AS total_orders
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p_brand
ORDER BY 
    avg_price DESC
LIMIT 10;