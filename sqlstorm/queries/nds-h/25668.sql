SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS unique_suppliers, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(p.p_retailprice) AS average_retail_price, 
    CONCAT('Supplier: ', s.s_name, ' | Nation: ', n.n_name) AS supplier_info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_size BETWEEN 1 AND 50
    AND p.p_comment LIKE '%excellent%'
GROUP BY 
    p.p_name, s.s_name, n.n_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 1
ORDER BY 
    total_available_quantity DESC, 
    average_retail_price ASC
LIMIT 10;
