SELECT 
    l_partkey, 
    SUM(l_quantity) AS total_quantity, 
    SUM(l_extendedprice) AS total_extended_price, 
    AVG(l_discount) AS average_discount
FROM 
    lineitem
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    l_partkey
ORDER BY 
    total_quantity DESC
LIMIT 10;