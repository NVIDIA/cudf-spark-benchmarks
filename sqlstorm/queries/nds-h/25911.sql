SELECT 
    p.p_name AS Part_Name, 
    s.s_name AS Supplier_Name, 
    c.c_name AS Customer_Name, 
    COUNT(o.o_orderkey) AS Total_Orders, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue, 
    RANK() OVER (PARTITION BY p.p_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS Revenue_Rank,
    SUBSTRING(s.s_address, 1, 15) AS Short_Address,
    CONCAT(n.n_name, ', ', r.r_name) AS Nation_Region 
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
    nation n ON s.s_nationkey = n.n_nationkey 
JOIN 
    region r ON n.n_regionkey = r.r_regionkey 
WHERE 
    o.o_orderdate >= '1997-01-01' AND 
    o.o_orderdate < '1998-01-01' AND 
    s.s_comment LIKE '%special%' 
GROUP BY 
    p.p_name, s.s_name, c.c_name, n.n_name, r.r_name, s.s_address 
HAVING 
    COUNT(o.o_orderkey) > 5 
ORDER BY 
    Total_Revenue DESC, Revenue_Rank;