SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    SUM(l.l_quantity) AS Total_Quantity,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    AVG(l.l_extendedprice) AS Average_Extended_Price,
    CONCAT('Region: ', r.r_name, ', Nation: ', n.n_name) AS Region_Nation_Info
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    c.c_acctbal > 1000 AND 
    l.l_shipdate BETWEEN '1996-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, r.r_name, n.n_name
HAVING 
    SUM(l.l_quantity) > 500
ORDER BY 
    Total_Quantity DESC, Average_Extended_Price ASC;