
SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue, 
    n_nationkey, 
    n_name
FROM 
    lineitem 
JOIN 
    orders ON l_orderkey = o_orderkey
JOIN 
    customer ON o_custkey = c_custkey
JOIN 
    partsupp ON l_partkey = ps_partkey
JOIN 
    supplier ON s_suppkey = ps_suppkey
JOIN 
    nation ON c_nationkey = n_nationkey
WHERE 
    l_shipdate >= '1994-01-01' AND 
    l_shipdate < '1995-01-01'
GROUP BY 
    n_nationkey, n_name
ORDER BY 
    revenue DESC;
