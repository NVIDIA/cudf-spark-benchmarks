
SELECT 
    p.p_name, 
    s.s_name, 
    CONCAT('Supplier: ', s.s_name, ' supplies ', p.p_name, ' with a retail price of ', CAST(p.p_retailprice AS STRING) , ' and has a comment: ', s.s_comment) AS detail_info,
    COUNT(l.l_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue
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
    p.p_comment LIKE '%fragile%'
    AND s.s_address LIKE '123%'
GROUP BY 
    p.p_name, s.s_name, s.s_comment, p.p_retailprice
HAVING 
    COUNT(l.l_orderkey) > 100
ORDER BY 
    total_revenue DESC
LIMIT 10;
