
SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Comment: ', ps.ps_comment) AS info,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_name LIKE 'Supplier%' 
    AND p.p_comment NOT LIKE '%faulty%'
GROUP BY 
    s.s_suppkey, p.p_partkey, p.p_name, ps.ps_comment, s.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;
