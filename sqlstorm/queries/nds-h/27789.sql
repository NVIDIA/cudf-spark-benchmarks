SELECT 
    p.p_name AS Part_Name,
    s.s_name AS Supplier_Name,
    CONCAT('Region: ', r.r_name, ' - ', r.r_comment) AS Region_Info,
    CONCAT('Customer Segment: ', c.c_mktsegment, ' | Address: ', c.c_address) AS Customer_Info,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS Total_Returns
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    p.p_name LIKE '%widget%'
    AND o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    p.p_name, s.s_name, r.r_name, r.r_comment, c.c_mktsegment, c.c_address
ORDER BY 
    Total_Revenue DESC;