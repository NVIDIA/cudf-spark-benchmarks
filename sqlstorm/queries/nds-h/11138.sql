SELECT 
    sum(l_extendedprice * (1 - l_discount)) AS revenue, 
    n_name AS nation
FROM 
    customer, 
    orders, 
    lineitem, 
    supplier, 
    nation
WHERE 
    c_custkey = o_custkey 
    AND o_orderkey = l_orderkey 
    AND l_suppkey = s_suppkey 
    AND s_nationkey = n_nationkey 
    AND o_orderdate >= DATE '1995-01-01' 
    AND o_orderdate < DATE '1996-01-01' 
GROUP BY 
    n_name
ORDER BY 
    revenue DESC;
