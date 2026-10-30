SELECT 
    l_orderkey,
    COUNT(*) AS line_count,
    SUM(l_extendedprice) AS total_extended_price,
    AVG(l_discount) AS average_discount
FROM 
    lineitem
WHERE 
    l_shipdate >= DATE '1997-01-01' AND 
    l_shipdate < DATE '1998-01-01'
GROUP BY 
    l_orderkey
ORDER BY 
    total_extended_price DESC
LIMIT 100;