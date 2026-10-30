SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    o.o_orderkey AS Order_Key,
    COUNT(DISTINCT l.l_orderkey) AS Order_Count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    AVG(LENGTH(p.p_comment)) AS Avg_Part_Comment_Length,
    MAX(CAST(SUBSTRING(s.s_comment, 1, 50) AS STRING)) AS Short_Supplier_Comment,
    CONCAT(n.n_name, ' - ', r.r_name) AS Location
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_retailprice > 100
    AND o.o_orderdate >= DATE '1997-01-01'
    AND LENGTH(s.s_comment) > 30
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, n.n_name, r.r_name
ORDER BY 
    Total_Revenue DESC, Avg_Part_Comment_Length ASC
LIMIT 50;