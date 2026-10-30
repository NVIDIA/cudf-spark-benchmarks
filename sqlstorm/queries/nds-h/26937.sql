
SELECT 
    p.p_name AS Part_Name,
    COUNT(DISTINCT s.s_suppkey) AS Supplier_Count,
    SUM(ps.ps_availqty) AS Total_Available_Quantity,
    AVG(ps.ps_supplycost) AS Average_Supply_Cost,
    SUBSTRING(p.p_comment, 1, 10) AS Short_Comment,
    r.r_name AS Region_Name,
    REPLACE(n.n_name, 'Nation', 'Country') AS Adjusted_Nation
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
    p.p_retailprice > 100
    AND p.p_type LIKE '%brass%'
    AND s.s_acctbal > 5000
GROUP BY 
    p.p_name, r.r_name, n.n_name, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    Total_Available_Quantity DESC
LIMIT 10;
