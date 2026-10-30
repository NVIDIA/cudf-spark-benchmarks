
SELECT 
    s.s_name AS supplier_name,
    p.p_name AS part_name,
    SUM(ps.ps_availqty) AS total_available_quantity,
    MIN(l.l_discount) AS min_discount,
    MAX(l.l_tax) AS max_tax,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    r.r_name AS region_name,
    TRIM(BOTH ' ' FROM s.s_comment) AS trimmed_supplier_comment
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
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND p.p_type LIKE '%metal%'
GROUP BY 
    s.s_name, p.p_name, r.r_name, s.s_comment
HAVING 
    SUM(ps.ps_availqty) > 1000
ORDER BY 
    total_available_quantity DESC, unique_customers DESC;
