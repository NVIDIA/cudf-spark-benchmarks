
SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    p.p_type, 
    s.s_name AS supplier_name, 
    COUNT(DISTINCT l.l_orderkey) AS order_count, 
    SUM(l.l_quantity) AS total_quantity, 
    AVG(l.l_extendedprice) AS avg_price, 
    MAX(l.l_discount) AS max_discount, 
    MIN(l.l_tax) AS min_tax,
    CONCAT(SUBSTRING(p.p_name, 1, 10), '...') AS truncated_name,
    REPLACE(p.p_comment, ' ', '-') AS modified_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, p.p_type, s.s_name,
    p.p_comment
HAVING 
    COUNT(DISTINCT l.l_orderkey) > 5 
ORDER BY 
    total_quantity DESC, avg_price ASC;
