SELECT 
    CONCAT(s.s_name, ' ', s.s_address) AS supplier_info,
    LEFT(p.p_name, 10) AS short_part_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    rg.r_name AS region_name
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
    region rg ON n.n_regionkey = rg.r_regionkey
WHERE 
    s.s_comment LIKE '%special%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    supplier_info, short_part_name, rg.r_name
HAVING 
    COUNT(DISTINCT c.c_custkey) > 5
ORDER BY 
    total_revenue DESC, region_name ASC;