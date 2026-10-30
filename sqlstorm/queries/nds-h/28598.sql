SELECT 
    p.p_name, 
    ps.ps_supplycost, 
    SUM(l.l_quantity) AS total_quantity,
    CONCAT(c.c_name, ' from ', n.n_name, ' - ', r.r_name) AS supplier_location,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment
FROM 
    part p
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON c.c_custkey = l.l_orderkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_size BETWEEN 10 AND 20
    AND l.l_shipdate >= '1997-01-01'
    AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    p.p_name, ps.ps_supplycost, c.c_name, n.n_name, r.r_name, p.p_comment
HAVING 
    SUM(l.l_quantity) > 50
ORDER BY 
    total_quantity DESC, p.p_name ASC;