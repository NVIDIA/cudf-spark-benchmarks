SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUBSTRING(p.p_comment, 1, 10) AS short_comment,
    CONCAT('Supplier Name: ', s.s_name, ', Address: ', s.s_address) AS supplier_info,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity,
    AVG(l.l_extendedprice) AS avg_price
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, s.s_name, s.s_address, p.p_comment
HAVING 
    AVG(l.l_discount) > 0.05
ORDER BY 
    total_quantity DESC, p.p_name ASC
LIMIT 100;
