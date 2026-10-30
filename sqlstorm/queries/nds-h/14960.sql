SELECT 
    n_name, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    customer 
JOIN 
    orders ON c_custkey = o_custkey 
JOIN 
    lineitem ON o_orderkey = l_orderkey 
JOIN 
    supplier ON s_suppkey = l_suppkey 
JOIN 
    partsupp ON ps_suppkey = s_suppkey 
JOIN 
    part ON ps_partkey = p_partkey 
JOIN 
    nation ON c_nationkey = n_nationkey 
GROUP BY 
    n_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;
