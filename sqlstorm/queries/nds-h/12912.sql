SELECT 
    n_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
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
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    n_name 
ORDER BY 
    total_revenue DESC;