SELECT 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(ps.ps_availqty) AS total_available_quantity,
    AVG(p.p_retailprice) AS average_price,
    CONCAT(
        'Region: ', r.r_name, ', Nation: ', n.n_name, ', Supplier: ', s.s_name
    ) AS detailed_info
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    p.p_name LIKE '%Widget%' 
    AND p.p_size > 10 
    AND p.p_retailprice < 100 
GROUP BY 
    p.p_brand, r.r_name, n.n_name, s.s_name 
HAVING 
    COUNT(DISTINCT ps.ps_suppkey) > 5 
ORDER BY 
    average_price DESC, supplier_count ASC;
