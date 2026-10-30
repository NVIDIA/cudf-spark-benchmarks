SELECT 
    l_orderkey, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue, 
    o_orderdate,
    c_nationkey,
    n_name
FROM 
    lineitem
JOIN 
    orders ON lineitem.l_orderkey = orders.o_orderkey
JOIN 
    customer ON orders.o_custkey = customer.c_custkey
JOIN 
    nation ON customer.c_nationkey = nation.n_nationkey
WHERE 
    l_shipdate >= '1997-01-01' 
    AND l_shipdate <= '1997-12-31'
GROUP BY 
    l_orderkey, 
    o_orderdate, 
    c_nationkey, 
    n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;