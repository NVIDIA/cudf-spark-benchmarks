
SELECT 
    p.p_brand, 
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
    SUM(l.l_quantity) AS total_quantity_sold, 
    AVG(l.l_extendedprice) AS avg_extended_price,
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    CONCAT('Brand: ', p.p_brand, ', Type: ', p.p_type) AS brand_type_info
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey 
JOIN 
    customer c ON o.o_custkey = c.c_custkey 
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey 
WHERE 
    LENGTH(p.p_comment) > 10 
    AND c.c_mktsegment = 'BUILDING' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    p.p_brand, p.p_name, p.p_type, short_name, brand_type_info
HAVING 
    SUM(l.l_quantity) > 1000 
ORDER BY 
    supplier_count DESC, total_quantity_sold ASC;
