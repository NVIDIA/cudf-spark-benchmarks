SELECT 
    n_name AS nation_name,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
FROM 
    lineitem
JOIN 
    orders ON o_orderkey = l_orderkey
JOIN 
    customer ON c_custkey = o_custkey
JOIN 
    nation ON n_nationkey = c_nationkey
WHERE 
    l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1996-12-31'
GROUP BY 
    n_name
ORDER BY 
    total_revenue DESC;