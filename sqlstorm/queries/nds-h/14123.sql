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
    supplier ON s_suppkey = l_suppkey
JOIN 
    partsupp ON ps_partkey = l_partkey AND ps_suppkey = s_suppkey
JOIN 
    nation ON s_nationkey = n_nationkey
WHERE 
    l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
GROUP BY 
    n_name
ORDER BY 
    total_revenue DESC;
