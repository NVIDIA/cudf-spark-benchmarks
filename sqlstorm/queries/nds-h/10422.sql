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
    partsupp ON lineitem.l_partkey = partsupp.ps_partkey 
JOIN 
    nation ON supplier.s_nationkey = nation.n_nationkey
WHERE 
    o_orderdate >= DATE '1995-01-01' AND o_orderdate < DATE '1996-01-01'
GROUP BY 
    n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;