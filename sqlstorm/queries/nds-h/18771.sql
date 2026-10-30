SELECT 
    p_brand, 
    SUM(l_extendedprice * (1 - l_discount)) AS revenue
FROM 
    part 
JOIN 
    lineitem ON p_partkey = l_partkey
JOIN 
    orders ON l_orderkey = o_orderkey
WHERE 
    o_orderdate >= '1997-01-01' AND o_orderdate < '1997-02-01'
GROUP BY 
    p_brand
ORDER BY 
    revenue DESC;