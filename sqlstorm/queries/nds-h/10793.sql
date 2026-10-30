SELECT 
    n_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    part 
JOIN 
    lineitem ON part.p_partkey = lineitem.l_partkey
JOIN 
    partsupp ON lineitem.l_partkey = partsupp.ps_partkey
JOIN 
    supplier ON partsupp.ps_suppkey = supplier.s_suppkey
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey
WHERE 
    l_shipdate >= '1995-01-01' AND l_shipdate < '1996-01-01'
GROUP BY 
    n_name
ORDER BY 
    total_revenue DESC;