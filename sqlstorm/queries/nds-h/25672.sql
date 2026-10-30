
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    c.c_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    MAX(LENGTH(p.p_comment)) AS max_comment_length,
    MIN(LENGTH(c.c_comment)) AS min_customer_comment_length
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
    p.p_brand LIKE 'Brand%G' 
    AND s.s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
GROUP BY 
    p.p_partkey, p.p_name, s.s_name, c.c_name, s.s_acctbal, p.p_comment, c.c_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    total_revenue DESC, order_count DESC;
