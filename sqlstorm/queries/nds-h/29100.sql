
SELECT 
    p.p_name, 
    s.s_name, 
    SUBSTRING(s.s_address, 1, 20) AS short_address, 
    CONCAT('Supplier: ', s.s_name, ', Part: ', p.p_name) AS descriptive_info,
    COUNT(o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_comment LIKE '%rapid%' 
    AND p.p_brand = 'Brand#20' 
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, s.s_address
HAVING 
    COUNT(o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC;
