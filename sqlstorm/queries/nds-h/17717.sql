SELECT 
    n_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    lineitem 
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey 
JOIN 
    customer ON orders.o_custkey = customer.c_custkey 
JOIN 
    supplier ON lineitem.l_suppkey = supplier.s_suppkey 
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey 
GROUP BY 
    n_name 
ORDER BY 
    revenue DESC;
