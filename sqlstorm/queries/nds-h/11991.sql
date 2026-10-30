SELECT 
    n_name, 
    COUNT(DISTINCT o_orderkey) AS total_orders, 
    SUM(l_extendedprice) AS total_revenue
FROM 
    nation 
JOIN 
    supplier ON n_nationkey = s_nationkey
JOIN 
    partsupp ON s_suppkey = ps_suppkey
JOIN 
    part ON ps_partkey = p_partkey
JOIN 
    lineitem ON p_partkey = l_partkey
JOIN 
    orders ON l_orderkey = o_orderkey
GROUP BY 
    n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
