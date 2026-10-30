
SELECT 
    p.p_name, 
    s.s_name, 
    SUM(ps.ps_availqty) AS total_available_quantity,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    LEFT(p.p_comment, 15) AS short_comment,
    CONCAT(r.r_name, ': ', n.n_name) AS region_nation_info
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
    p.p_name LIKE 'rubber%' 
    AND s.s_acctbal > 1000.00
GROUP BY 
    p.p_name, 
    s.s_name, 
    r.r_name, 
    n.n_name, 
    p.p_comment
HAVING 
    SUM(ps.ps_availqty) > 500
ORDER BY 
    total_orders DESC, 
    total_available_quantity ASC;
