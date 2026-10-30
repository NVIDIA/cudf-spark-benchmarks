SELECT 
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderdate,
    c_name,
    s_name
FROM 
    lineitem
JOIN 
    orders ON l_orderkey = o_orderkey
JOIN 
    customer ON o_custkey = c_custkey
JOIN 
    partsupp ON l_partkey = ps_partkey
JOIN 
    supplier ON ps_suppkey = s_suppkey
GROUP BY 
    l_orderkey, o_orderdate, c_name, s_name
ORDER BY 
    total_revenue DESC
LIMIT 100;
