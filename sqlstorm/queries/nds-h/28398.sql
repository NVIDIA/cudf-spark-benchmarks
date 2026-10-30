SELECT 
    CONCAT('Supplier: ', s.s_name, ', Address: ', s.s_address, ', Nation: ', n.n_name) AS Supplier_Info,
    SUM(l.l_quantity) AS Total_Quantity,
    AVG(l.l_extendedprice) AS Avg_Extended_Price,
    MIN(l.l_discount) AS Min_Discount,
    MAX(l.l_tax) AS Max_Tax,
    COUNT(DISTINCT o.o_orderkey) AS Order_Count
FROM 
    supplier AS s
JOIN 
    partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part AS p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    orders AS o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer AS c ON o.o_custkey = c.c_custkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
AND 
    n.n_name LIKE '%US%'
GROUP BY 
    s.s_suppkey, s.s_name, s.s_address, n.n_name
HAVING 
    SUM(l.l_quantity) > 100
ORDER BY 
    Total_Quantity DESC;