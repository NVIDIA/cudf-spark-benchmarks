SELECT 
    n.n_name AS nation_name,
    r.r_name AS region_name,
    SUM(ps.ps_supplycost * l.l_quantity) AS total_supplycost
FROM 
    lineitem l
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND l.l_shipdate <= '1997-12-31'
GROUP BY 
    n.n_name, r.r_name
ORDER BY 
    total_supplycost DESC
LIMIT 10;