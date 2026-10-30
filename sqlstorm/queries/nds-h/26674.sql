
SELECT 
    p.p_name, 
    s.s_name, 
    c.c_name, 
    SUM(l.l_quantity) AS total_quantity,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    LOWER(REPLACE(REPLACE(p.p_comment, ' ', '_'), '.', '')) AS transformed_comment
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
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
WHERE 
    p.p_size > 10 AND 
    s.s_acctbal > 5000 
GROUP BY 
    p.p_name, s.s_name, c.c_name, p.p_comment 
HAVING 
    SUM(l.l_quantity) > 100 
ORDER BY 
    total_quantity DESC, transformed_comment ASC;
