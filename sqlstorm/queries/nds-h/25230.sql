
SELECT 
    CONCAT(s.s_name, ' (', n.n_name, ')') AS supplier_info, 
    p.p_name,
    REGEXP_REPLACE(p.p_comment, '([^a-zA-Z0-9 ])', '') AS sanitized_comment,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    LENGTH(p.p_name) > 20
    AND s.s_comment LIKE '%premium%'
GROUP BY 
    s.s_name, n.n_name, p.p_name, p.p_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    total_revenue DESC
LIMIT 10;
