
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    TRIM(UPPER(CONCAT(s.s_name, ' - ', p.p_name))) AS supplier_part_info,
    LEFT(s.s_comment, 50) AS shortened_supplier_comment
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
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31' 
    AND c.c_mktsegment = 'BUILDING'
GROUP BY 
    s.s_name, p.p_name, s.s_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000.00
ORDER BY 
    total_revenue DESC, supplier_name;
