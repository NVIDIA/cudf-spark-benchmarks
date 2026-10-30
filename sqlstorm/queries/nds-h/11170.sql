SELECT 
    region.r_name,
    nation.n_name,
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS total_revenue
FROM 
    region
JOIN 
    nation ON region.r_regionkey = nation.n_regionkey
JOIN 
    supplier ON nation.n_nationkey = supplier.s_nationkey
JOIN 
    partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
JOIN 
    part ON partsupp.ps_partkey = part.p_partkey
JOIN 
    lineitem ON part.p_partkey = lineitem.l_partkey
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
WHERE 
    lineitem.l_shipdate >= DATE '1998-01-01'
    AND lineitem.l_shipdate < DATE '1998-02-01'
GROUP BY 
    region.r_name, nation.n_name
ORDER BY 
    total_revenue DESC;
