SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    n_name,
    r_name
FROM 
    lineitem
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN 
    customer ON orders.o_custkey = customer.c_custkey
JOIN 
    nation ON customer.c_nationkey = nation.n_nationkey
JOIN 
    region ON nation.n_regionkey = region.r_regionkey
WHERE 
    l_shipdate >= '1997-01-01' AND l_shipdate < '1997-12-31'
GROUP BY 
    n_name,
    r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;