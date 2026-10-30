
SELECT 
    p.p_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    POSITION('excellent' IN p.p_comment) AS excellent_comment_position,
    CONCAT('Product: ', p.p_name, ', Available: ', SUM(ps.ps_availqty)) AS product_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2 AND 
    SUM(ps.ps_availqty) >= 100
ORDER BY 
    supplier_count DESC, total_available_quantity ASC;
