SELECT 
    nation.n_name,
    region.r_name,
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS revenue
FROM 
    lineitem
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN 
    customer ON orders.o_custkey = customer.c_custkey
JOIN 
    supplier ON lineitem.l_suppkey = supplier.s_suppkey
JOIN 
    partsupp ON lineitem.l_partkey = partsupp.ps_partkey AND supplier.s_suppkey = partsupp.ps_suppkey
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey
JOIN 
    region ON nation.n_regionkey = region.r_regionkey
WHERE 
    lineitem.l_shipdate >= DATE '1994-01-01' AND lineitem.l_shipdate < DATE '1995-01-01'
GROUP BY 
    nation.n_name, region.r_name
ORDER BY 
    revenue DESC;
