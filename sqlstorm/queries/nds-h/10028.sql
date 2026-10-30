SELECT 
    o_orderkey, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    orders 
JOIN 
    lineitem ON o_orderkey = l_orderkey
WHERE 
    o_orderdate >= DATE '1997-01-01' AND o_orderdate < DATE '1997-02-01'
GROUP BY 
    o_orderkey
ORDER BY 
    revenue DESC
LIMIT 10;