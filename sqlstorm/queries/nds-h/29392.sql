SELECT 
    CONCAT(c.c_name, ' from ', s.s_name, ': ', 
           REPLACE(SUBSTRING(p.p_name, 1, 10), ' ', '-') , '...', 
           CASE 
               WHEN LENGTH(p.p_comment) > 20 THEN CONCAT(SUBSTRING(p.p_comment, 1, 20), '...') 
               ELSE p.p_comment 
           END) AS product_summary,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS total_orders
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
    part p ON ps.ps_partkey = p.p_partkey
WHERE 
    c.c_mktsegment = 'BUILDING' 
    AND l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    c.c_name, s.s_name, p.p_name, p.p_comment
ORDER BY 
    total_revenue DESC
LIMIT 10;