SELECT 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    n_name,
    extract(year from o_orderdate) AS year
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
    part ON l_partkey = p_partkey
JOIN 
    nation ON s_nationkey = n_nationkey
WHERE 
    o_orderdate >= DATE '1995-01-01' AND 
    o_orderdate < DATE '1996-01-01' AND 
    n_name IN ('FRANCE', 'GERMANY', 'UNITED KINGDOM')
GROUP BY 
    n_name, year
ORDER BY 
    revenue DESC;
