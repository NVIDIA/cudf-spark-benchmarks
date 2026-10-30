
SELECT 
    s.s_name AS Supplier_Name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales,
    MIN(l.l_shipdate) AS First_Shipment_Date,
    MAX(l.l_shipdate) AS Last_Shipment_Date,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUBSTRING(s.s_comment, 1, 50) AS Supplier_Comment_Summary
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_type LIKE '%brass%'
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    s.s_name, s.s_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY 
    Total_Sales DESC
LIMIT 10;
