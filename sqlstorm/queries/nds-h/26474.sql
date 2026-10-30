
SELECT 
    CONCAT(s.s_name, ' - ', p.p_name) AS SupplierPartName, 
    REPLACE(p.p_comment, 'fragile', 'delicate') AS UpdatedComment, 
    LENGTH(p.p_name) AS PartNameLength,
    SUBSTRING(p.p_type, 1, 10) AS ShortPartType,
    UPPER(s.s_name) AS SupplierUppercase,
    COUNT(DISTINCT o.o_orderkey) AS TotalOrders
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    s.s_name LIKE '%Inc%'
    AND p.p_size BETWEEN 5 AND 20
GROUP BY 
    s.s_name, p.p_name, p.p_comment, p.p_type
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    TotalOrders DESC, PartNameLength ASC;
