
SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name, 
    CONCAT(REPLACE(s.s_name, 'Supplier', 'Sup'), ' - ', s.s_phone) AS formatted_supplier_info,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice) AS total_revenue
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
WHERE 
    p.p_comment LIKE '%red%' 
    AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY 
    SUBSTRING(p.p_name, 1, 10), 
    CONCAT(REPLACE(s.s_name, 'Supplier', 'Sup'), ' - ', s.s_phone)
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC, 
    short_name ASC;
