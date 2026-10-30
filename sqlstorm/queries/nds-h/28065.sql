SELECT 
    CONCAT('Supplier: ', s.s_name, ' - Part: ', p.p_name, ' - Order Cost: ', CAST(SUM(l.l_extendedprice * (1 - l.l_discount)) AS DECIMAL(12, 2)))
    AS order_summary,
    s.s_name,
    p.p_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_extended_price,
    AVG(CASE WHEN l.l_discount > 0 THEN l.l_discount ELSE NULL END) AS avg_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
FROM 
    supplier s 
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey 
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    p.p_brand LIKE 'Brand%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    total_extended_price DESC;