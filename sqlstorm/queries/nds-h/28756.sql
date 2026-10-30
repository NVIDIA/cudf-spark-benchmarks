SELECT 
    CONCAT_WS(' | ', p.p_name, s.s_name, c.c_name) AS Product_Supplier_Customer,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    AVG(l.l_quantity) AS Average_Quantity,
    MAX(l.l_tax) AS Max_Tax,
    MIN(p.p_retailprice) AS Min_Retail_Price
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    part p ON l.l_partkey = p.p_partkey
WHERE 
    c.c_mktsegment = 'BUILDING' 
    AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY 
    p.p_name, s.s_name, c.c_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    Total_Revenue DESC;