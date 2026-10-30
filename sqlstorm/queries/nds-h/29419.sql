
SELECT 
    p.p_name,
    COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
    SUM(CASE WHEN o.o_orderstatus = 'F' THEN l.l_quantity ELSE 0 END) AS total_filled_quantity,
    AVG(l.l_extendedprice) AS avg_extended_price,
    CONCAT(LEFT(p.p_comment, 20), '...') AS short_comment,
    r.r_name AS region_name
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
WHERE 
    p.p_name LIKE '%widget%' 
    AND o.o_orderdate >= DATE '1995-01-01'
GROUP BY 
    p.p_name, r.r_name, p.p_comment
HAVING 
    COUNT(DISTINCT s.s_suppkey) > 5 
ORDER BY 
    total_filled_quantity DESC, avg_extended_price ASC;
