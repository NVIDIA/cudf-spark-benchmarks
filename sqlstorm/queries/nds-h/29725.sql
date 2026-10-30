SELECT 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue, 
    AVG(l.l_quantity) AS avg_quantity, 
    MAX(l.l_discount) AS max_discount, 
    MIN(p.p_size) AS min_size
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_comment LIKE '%special%' 
    AND s.s_phone LIKE '1-800-%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_brand
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 10
ORDER BY 
    total_revenue DESC;