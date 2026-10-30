SELECT 
    CONCAT(SUBSTRING(s_name, 1, 10), '...', ' ', r_name) AS Supplier_Region,
    COUNT(DISTINCT o_orderkey) AS Total_Orders,
    AVG(o_totalprice) AS Average_Order_Value,
    SUM(l_quantity) AS Total_Quantity_Supplied
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    r.r_name LIKE '%NA%' 
    AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31' 
    AND l_returnflag = 'N'
GROUP BY 
    r_name, s_name
ORDER BY 
    Total_Quantity_Supplied DESC
LIMIT 10;