
SELECT 
    CONCAT(s.s_name, ' - ', p.p_name) AS Supplier_Product,
    SUBSTRING(s.s_address, 1, 15) AS Address_Partial,
    COUNT(DISTINCT c.c_custkey) AS Total_Customers,
    SUM(l.l_quantity) AS Total_Quantity_Supplied,
    AVG(l.l_discount) * 100 AS Average_Discount_Percentage,
    REGEXP_REPLACE(s.s_comment, '\\s+', ' ') AS Cleaned_Comment
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
WHERE 
    s.s_acctbal > 5000 AND 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, p.p_name, s.s_address, s.s_comment
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    Average_Discount_Percentage DESC
LIMIT 10;
