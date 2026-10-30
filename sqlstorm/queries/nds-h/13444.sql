SELECT 
    l_orderkey, 
    SUM(l_extendedprice) AS total_revenue, 
    AVG(l_discount) AS average_discount
FROM 
    lineitem
WHERE 
    l_shipdate >= '1997-01-01' AND l_shipdate < '1997-12-31'
GROUP BY 
    l_orderkey
ORDER BY 
    total_revenue DESC
LIMIT 100;