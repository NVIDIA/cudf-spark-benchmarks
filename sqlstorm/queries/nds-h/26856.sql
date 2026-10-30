SELECT 
    p.p_name AS Part_Name,
    SUM(ps.ps_availqty) AS Total_Available_Quantity,
    AVG(ps.ps_supplycost) AS Average_Supply_Cost,
    SUBSTRING(p.p_comment, 1, 15) AS Short_Comment,
    COUNT(DISTINCT s.s_suppkey) AS Unique_Suppliers,
    REPLACE(s.s_name, 'Inc', 'Incorporated') AS Modified_Supplier_Name,
    CONCAT(LEFT(p.p_type, 10), '_Type') AS Type_Label,
    LENGTH(p.p_comment) AS Comment_Length,
    CASE 
        WHEN p.p_retailprice > 100 THEN 'Expensive'
        ELSE 'Affordable'
    END AS Price_Category
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE 
    p.p_size BETWEEN 1 AND 50
GROUP BY 
    p.p_name, p.p_comment, s.s_name, p.p_type, p.p_retailprice
HAVING 
    SUM(ps.ps_availqty) > 10
ORDER BY 
    Total_Available_Quantity DESC, p.p_name ASC
LIMIT 100;
