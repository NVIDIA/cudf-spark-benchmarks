SELECT 
    p.p_name, 
    s.s_name, 
    n.n_name, 
    CASE 
        WHEN LENGTH(p.p_comment) > 20 THEN CONCAT(SUBSTRING(p.p_comment, 1, 20), '...')
        ELSE p.p_comment 
    END AS truncated_comment,
    SUM(l.l_quantity) AS total_quantity,
    AVG(o.o_totalprice) AS avg_order_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    n.n_name LIKE 'A%'
GROUP BY 
    p.p_name, s.s_name, n.n_name, truncated_comment
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    avg_order_price DESC, total_quantity DESC
LIMIT 10;
