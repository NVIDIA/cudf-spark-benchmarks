
SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    CONCAT(c.c_name, ' from ', c.c_address, ', ', n.n_name, ' - ', r.r_name) AS Customer_Info,
    COUNT(DISTINCT o.o_orderkey) AS Order_Count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    SUBSTRING(p.p_comment, 1, 10) AS Short_Comment,
    CHAR_LENGTH(p.p_comment) AS Comment_Length,
    CASE 
        WHEN CHAR_LENGTH(p.p_comment) > 10 THEN 'Long Comment' 
        ELSE 'Short Comment' 
    END AS Comment_Type
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
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_name LIKE '%rubber%' AND 
    o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, c.c_address, n.n_name, r.r_name, p.p_comment
ORDER BY 
    Total_Revenue DESC, Part_Name
LIMIT 100;
