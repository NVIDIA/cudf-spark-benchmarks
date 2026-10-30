SELECT 
    p.p_name,
    s.s_name,
    c.c_name,
    SUBSTRING(p.p_comment, 1, 20) AS short_comment,
    LENGTH(p.p_comment) AS comment_length,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    AVG(l.l_quantity) AS avg_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000 THEN 'High Revenue' 
        ELSE 'Low Revenue' 
    END AS revenue_category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE 
    p.p_type LIKE '%brass%'
    AND s.s_comment NOT LIKE '%urgent%'
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, short_comment, comment_length
ORDER BY 
    total_revenue DESC, comment_length ASC
LIMIT 50;