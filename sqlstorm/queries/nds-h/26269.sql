SELECT 
    p.p_name, 
    COUNT(DISTINCT s.s_suppkey) AS supplier_count, 
    SUM(ps.ps_availqty) AS total_available_quantity, 
    AVG(l.l_quantity) AS average_order_quantity, 
    MAX(l.l_extendedprice) AS max_extended_price, 
    MIN(RTRIM(p.p_comment) || ' - ' || RTRIM(s.s_name)) AS min_supplier_comment
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
WHERE 
    p.p_size BETWEEN 5 AND 20 
    AND o.o_orderdate >= '1997-01-01'
GROUP BY 
    p.p_name
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 2
ORDER BY 
    total_available_quantity DESC;