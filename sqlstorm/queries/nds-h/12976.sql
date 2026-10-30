SELECT 
    region.r_name, 
    nation.n_name, 
    supplier.s_name, 
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS total_revenue
FROM 
    lineitem 
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey 
JOIN 
    customer ON orders.o_custkey = customer.c_custkey 
JOIN 
    supplier ON lineitem.l_suppkey = supplier.s_suppkey 
JOIN 
    partsupp ON lineitem.l_partkey = partsupp.ps_partkey 
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey 
JOIN 
    region ON nation.n_regionkey = region.r_regionkey 
WHERE 
    orders.o_orderdate >= DATE '1997-01-01' AND orders.o_orderdate < DATE '1997-12-31'
GROUP BY 
    region.r_name, nation.n_name, supplier.s_name
ORDER BY 
    total_revenue DESC;