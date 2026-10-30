SELECT 
    CONCAT(c.c_name, ' from ', s.s_name) AS Supplier_Customer,
    p.p_name AS Part_Name,
    SUM(l.l_quantity) AS Total_Quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Revenue_After_Discount,
    r.r_name AS Region_Name,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_brand LIKE 'Brand%ABC%' 
    AND s.s_comment NOT LIKE '%wrong%'
GROUP BY 
    c.c_name, s.s_name, p.p_name, r.r_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    Revenue_After_Discount DESC;
