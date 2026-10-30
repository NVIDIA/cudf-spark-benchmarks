SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    SUM(l.l_quantity) AS Total_Quantity,
    COUNT(DISTINCT o.o_orderkey) AS Order_Count,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS Avg_Selling_Price,
    r.r_name AS Region_Name,
    SUBSTR(p.p_comment, 1, 20) AS Short_Comment,
    LENGTH(p.p_name) AS Name_Length
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%East%'
    AND o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND p.p_size > 5
GROUP BY 
    p.p_name, s.s_name, r.r_name, p.p_comment
ORDER BY 
    Total_Quantity DESC, Avg_Selling_Price DESC;