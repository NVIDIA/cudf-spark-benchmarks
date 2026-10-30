SELECT 
    s.s_name AS Supplier_Name,
    COUNT(DISTINCT ps.ps_partkey) AS Unique_Parts_Supplied,
    SUM(ps.ps_availqty) AS Total_Available_Quantity,
    SUM(ps.ps_supplycost * ps.ps_availqty) AS Total_Supply_Cost,
    AVG(l.l_extendedprice) AS Average_Extended_Price,
    MAX(l.l_discount) AS Maximum_Discount,
    MIN(l.l_tax) AS Minimum_Tax,
    r.r_name AS Region_Name,
    n.n_name AS Nation_Name
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey 
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    s.s_comment NOT LIKE '%error%'
GROUP BY 
    s.s_name, r.r_name, n.n_name
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 10
ORDER BY 
    Total_Available_Quantity DESC, Supplier_Name ASC;
