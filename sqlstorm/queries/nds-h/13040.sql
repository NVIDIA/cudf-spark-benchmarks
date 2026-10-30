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
    nation ON s_nationkey = n_nationkey
WHERE 
    o_orderdate >= '1997-01-01' AND o_orderdate < '1998-01-01'
GROUP BY 
    n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;