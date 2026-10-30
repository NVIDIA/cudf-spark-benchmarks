SELECT 
    n_name AS nation, 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    lineitem 
JOIN 
    supplier ON l_suppkey = s_suppkey 
JOIN 
    partsupp ON l_partkey = ps_partkey AND s_suppkey = ps_suppkey 
JOIN 
    part ON ps_partkey = p_partkey 
JOIN 
    nation ON s_nationkey = n_nationkey 
GROUP BY 
    n_name 
ORDER BY 
    total_revenue DESC
LIMIT 10;
