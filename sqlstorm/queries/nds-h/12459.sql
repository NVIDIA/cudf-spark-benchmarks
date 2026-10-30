SELECT 
    n.n_name,
    SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_revenue
FROM 
    lineitem lp
JOIN 
    orders o ON lp.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    supplier s ON lp.l_suppkey = s.s_suppkey
JOIN 
    partsupp ps ON lp.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    lp.l_shipdate >= '1997-01-01' AND lp.l_shipdate <= '1997-12-31'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC;