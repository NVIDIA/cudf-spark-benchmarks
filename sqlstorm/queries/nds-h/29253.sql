
SELECT 
    CONCAT(s.s_name, ' (', SUBSTRING(s.s_address, 1, 20), '...)') AS supplier_info,
    p.p_name AS part_name,
    ps.ps_availqty AS available_quantity,
    REPLACE(p.p_comment, 'old', 'new') AS modified_comment,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 THEN 'High'
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) BETWEEN 500 AND 1000 THEN 'Medium'
        ELSE 'Low' 
    END AS revenue_category
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_comment LIKE '%urgent%'
    AND p.p_size BETWEEN 10 AND 20
GROUP BY 
    s.s_name, s.s_address, p.p_name, ps.ps_availqty, p.p_comment
ORDER BY 
    total_revenue DESC, supplier_info
LIMIT 100;
