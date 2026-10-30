SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_price_after_discount,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    CONCAT('Supplier: ', s.s_name, ', Product: ', p.p_name, ', Orders: ', COUNT(DISTINCT o.o_orderkey)) AS order_summary
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
WHERE 
    p.p_size BETWEEN 10 AND 20 
    AND s.s_acctbal > 1000
    AND l.l_shipdate >= '1997-01-01' 
GROUP BY 
    p.p_name, s.s_name 
HAVING 
    SUM(l.l_quantity) > 50 
ORDER BY 
    total_quantity DESC, avg_price_after_discount ASC;