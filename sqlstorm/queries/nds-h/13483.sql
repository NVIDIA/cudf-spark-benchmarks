SELECT 
    l_partkey,
    SUM(l_quantity) AS total_quantity,
    SUM(l_extendedprice) AS total_revenue
FROM 
    lineitem
WHERE 
    l_shipdate >= '1997-01-01' AND l_shipdate < '1998-01-01'
GROUP BY 
    l_partkey
ORDER BY 
    total_revenue DESC
LIMIT 10;