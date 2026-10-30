SELECT 
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
    o_orderdate,
    c_name,
    n_name,
    r_name
FROM 
    lineitem 
JOIN 
    orders ON l_orderkey = o_orderkey
JOIN 
    customer ON o_custkey = c_custkey
JOIN 
    supplier ON l_suppkey = s_suppkey
JOIN 
    partsupp ON l_partkey = ps_partkey
JOIN 
    nation ON s_nationkey = n_nationkey
JOIN 
    region ON n_regionkey = r_regionkey
WHERE 
    o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    l_orderkey, o_orderdate, c_name, n_name, r_name
ORDER BY 
    total_revenue DESC
LIMIT 10;