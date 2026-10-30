
SELECT 
    SUM(CASE WHEN LENGTH(p_name) BETWEEN 10 AND 20 THEN 1 ELSE 0 END) AS Within_Length,
    COUNT(DISTINCT s_name) AS Unique_Suppliers,
    AVG(p_retailprice) AS Average_Retail_Price,
    r_name AS Region_Name,
    CONCAT(n_name, ' - ', r_name) AS Nation_Region_Combination
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
    p_comment LIKE '%leather%'
GROUP BY 
    r_name, n_name
ORDER BY 
    Unique_Suppliers DESC, Average_Retail_Price ASC;
