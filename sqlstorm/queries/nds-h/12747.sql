SELECT 
    p.p_partkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    r.r_name,
    n.n_name
FROM 
    part p
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    supplier s ON l.l_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= DATE '1995-01-01'
    AND l.l_shipdate < DATE '1995-01-01' + INTERVAL '1' YEAR
GROUP BY 
    p.p_partkey, r.r_name, n.n_name
ORDER BY 
    revenue DESC
LIMIT 10;