SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    n_name,
    o_orderdate
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
    nation ON s_nationkey = n_nationkey
WHERE 
    l_shipdate >= '1994-01-01' AND l_shipdate < '1995-01-01'
GROUP BY 
    n_name, o_orderdate
ORDER BY 
    total_revenue DESC;
