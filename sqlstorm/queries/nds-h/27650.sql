
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(l.l_quantity) AS total_quantity, 
    COUNT(DISTINCT o.o_orderkey) AS order_count, 
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT(s.s_name, ' - ', s.s_phone) AS supplier_info
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
    l.l_shipdate >= '1997-01-01' 
    AND l.l_shipdate <= '1997-12-31' 
    AND s.s_acctbal > 1000 
GROUP BY 
    p.p_name, s.s_name, p.p_comment, s.s_phone 
HAVING 
    SUM(l.l_quantity) > 500 
ORDER BY 
    total_quantity DESC, short_comment;
