SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue, 
    n_name 
FROM 
    lineitem 
JOIN 
    orders ON l_orderkey = o_orderkey 
JOIN 
    customer ON o_custkey = c_custkey 
JOIN 
    supplier ON l_suppkey = s_suppkey 
JOIN 
    partsupp ON l_partkey = ps_partkey AND s_suppkey = ps_suppkey 
JOIN 
    nation ON c_nationkey = n_nationkey 
WHERE 
    l_shipdate >= '1997-01-01' 
    AND l_shipdate < '1997-12-31' 
GROUP BY 
    n_name 
ORDER BY 
    total_revenue DESC 
LIMIT 10;