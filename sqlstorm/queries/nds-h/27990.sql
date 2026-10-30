SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    c.c_name AS Customer_Name,
    o.o_orderkey AS Order_Number,
    o.o_orderdate AS Order_Date,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    r.r_name AS Region_Name,
    n.n_name AS Nation_Name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND p.p_name LIKE '%steel%'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, o.o_orderdate, r.r_name, n.n_name
ORDER BY 
    Total_Revenue DESC, Order_Date DESC
LIMIT 50;