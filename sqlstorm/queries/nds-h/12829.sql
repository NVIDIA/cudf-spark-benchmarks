SELECT 
    p.p_partkey, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    part AS p
JOIN 
    lineitem AS l ON p.p_partkey = l.l_partkey
JOIN 
    supplier AS s ON l.l_suppkey = s.s_suppkey
JOIN 
    partsupp AS ps ON p.p_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation AS n ON s.s_nationkey = n.n_nationkey
JOIN 
    region AS r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name = 'ASIA'
    AND l.l_shipdate >= DATE '1994-01-01'
    AND l.l_shipdate < DATE '1995-01-01'
GROUP BY 
    p.p_partkey
ORDER BY 
    revenue DESC
LIMIT 10;
