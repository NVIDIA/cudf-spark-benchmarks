SELECT 
    SUBSTR(p.p_name, 1, 20) AS Short_Name,
    REPLACE(s.s_name, 'Inc', 'Incorporated') AS Supplier_Name,
    CONCAT(CONCAT(c.c_name, ' - R'), r.r_name) AS Customer_Region,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS Returned_Value
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
    p.p_retailprice > 100.00
AND 
    o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    Short_Name, Supplier_Name, Customer_Region
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY 
    Total_Orders DESC, Returned_Value DESC;