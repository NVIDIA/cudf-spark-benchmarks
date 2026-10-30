SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    o.o_orderkey AS Order_ID,
    CONCAT('Region: ', r.r_name, ' | Nation: ', n.n_name) AS Location,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Sales,
    AVG(l.l_quantity) AS Average_Quantity,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders
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
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, r.r_name, n.n_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    Total_Sales DESC, Average_Quantity DESC;