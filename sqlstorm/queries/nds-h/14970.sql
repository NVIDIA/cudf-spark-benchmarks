SELECT 
    n_name, 
    COUNT(DISTINCT o_orderkey) AS order_count, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    customer 
JOIN 
    orders ON c_custkey = o_custkey 
JOIN 
    lineitem ON o_orderkey = l_orderkey 
JOIN 
    supplier ON l_suppkey = s_suppkey 
JOIN 
    partsupp ON l_partkey = ps_partkey AND s_suppkey = ps_suppkey 
JOIN 
    part ON ps_partkey = p_partkey 
JOIN 
    nation ON c_nationkey = n_nationkey 
GROUP BY 
    n_name 
ORDER BY 
    revenue DESC 
LIMIT 10;
