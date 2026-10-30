
SELECT 
    CONCAT_WS(' ', c.c_name, c.c_address) AS customer_info, 
    p.p_brand AS product_brand, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_extended_price,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    p.p_brand LIKE 'Brand#%'
    AND c.c_mktsegment = 'BUILDING'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    c.c_name, 
    c.c_address, 
    p.p_brand
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_quantity DESC;
