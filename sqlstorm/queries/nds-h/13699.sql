SELECT 
    nation.n_name, 
    SUM(lineitem.l_extendedprice * (1 - lineitem.l_discount)) AS total_revenue
FROM 
    lineitem
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN 
    customer ON orders.o_custkey = customer.c_custkey
JOIN 
    nation ON customer.c_nationkey = nation.n_nationkey
WHERE 
    lineitem.l_shipdate >= DATE '1995-01-01' 
    AND lineitem.l_shipdate < DATE '1996-01-01'
GROUP BY 
    nation.n_name
ORDER BY 
    total_revenue DESC;
