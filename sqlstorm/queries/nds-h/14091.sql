SELECT 
    l_orderkey,
    SUM(l_extendedprice * (1 - l_discount)) AS revenue,
    o_orderpriority
FROM 
    lineitem
JOIN 
    orders ON l_orderkey = o_orderkey
WHERE 
    l_shipdate >= '1995-01-01' AND l_shipdate < '1996-01-01'
GROUP BY 
    l_orderkey, o_orderpriority
ORDER BY 
    revenue DESC
LIMIT 10;
