SELECT 
    p.p_name,
    COUNT(DISTINCT l.l_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    MAX(l.l_shipdate) AS latest_ship_date,
    AVG(l.l_quantity) AS avg_quantity,
    SUBSTRING(p.p_comment, 1, 15) AS short_comment
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%EUROPE%' 
    AND l.l_shipdate >= DATE '1996-01-01'
GROUP BY 
    p.p_name, p.p_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) >= 10000
ORDER BY 
    total_revenue DESC, p_name ASC;