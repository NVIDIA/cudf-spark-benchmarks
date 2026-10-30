SELECT 
    p.p_name AS Part_Name,
    CONCAT('Manufacturer: ', p.p_mfgr, ' | Brand: ', p.p_brand) AS Manufacturer_Brand,
    LOWER(p.p_type) AS Lowercase_Type,
    SUBSTRING(p.p_comment, 1, 10) AS Short_Comment,
    COUNT(DISTINCT s.s_suppkey) AS Supplier_Count,
    AVG(ps.ps_supplycost) AS Average_Supply_Cost,
    MAX(l.l_linenumber) AS Max_Line_Item 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
GROUP BY 
    p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, LOWER(p.p_type), SUBSTRING(p.p_comment, 1, 10) 
HAVING 
    AVG(ps.ps_supplycost) > (SELECT AVG(ps_supplycost) FROM partsupp)
ORDER BY 
    Supplier_Count DESC, Max_Line_Item ASC;
