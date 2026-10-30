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
    nation ON c_nationkey = n_nationkey
GROUP BY 
    n_name, year
ORDER BY 
    year, revenue DESC
LIMIT 10;
