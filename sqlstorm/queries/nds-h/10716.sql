SELECT 
    n_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    lineitem 
JOIN 
    orders ON l_orderkey = o_orderkey 
JOIN 
    customer ON o_custkey = c_custkey 
JOIN 
    supplier ON l_suppkey = s_suppkey 
JOIN 
    partsupp ON l_partkey = ps_partkey 
JOIN 
    part ON ps_partkey = p_partkey 
JOIN 
    nation ON c_nationkey = n_nationkey 
WHERE 
    o_orderdate >= DATE '1997-01-01' 
    AND o_orderdate < DATE '1997-12-31' 
GROUP BY 
    n_name 
ORDER BY 
    total_revenue DESC;