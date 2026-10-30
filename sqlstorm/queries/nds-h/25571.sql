
SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ' supplied ', p.p_name) AS order_detail,
    SUBSTR(p.p_comment, 1, 15) || '...' AS short_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    customer c 
JOIN 
    orders o ON c.c_custkey = o.o_custkey 
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey 
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    part p ON l.l_partkey = p.p_partkey 
WHERE 
    c.c_acctbal > 1000 
    AND s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE '%USA%') 
GROUP BY 
    c.c_name, s.s_name, p.p_name, p.p_comment 
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 
ORDER BY 
    total_revenue DESC
LIMIT 10;
