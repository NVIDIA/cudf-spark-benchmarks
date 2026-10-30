SELECT 
    p.p_name AS Part_Name, 
    s.s_name AS Supplier_Name, 
    SUM(l.l_quantity) AS Total_Quantity_Sold, 
    ROUND(SUM(l.l_extendedprice * (1 - l.l_discount)), 2) AS Total_Revenue,
    LEFT(p.p_comment, 20) AS Short_Comment,
    CONCAT(n.n_name, ' - ', r.r_name) AS Nation_Region
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON l.l_partkey = p.p_partkey 
JOIN 
    orders o ON o.o_orderkey = l.l_orderkey 
JOIN 
    customer c ON c.c_custkey = o.o_custkey 
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    o.o_orderdate >= DATE '1996-01-01'
    AND o.o_orderdate < DATE '1997-01-01'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, s.s_name, Short_Comment, Nation_Region
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    Total_Revenue DESC, Total_Quantity_Sold DESC;