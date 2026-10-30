SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    n_name AS nation
FROM 
    lineitem
JOIN 
    orders ON l_orderkey = o_orderkey
JOIN 
    customer ON o_custkey = c_custkey
JOIN 
    nation ON c_nationkey = n_nationkey
GROUP BY 
    n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;
