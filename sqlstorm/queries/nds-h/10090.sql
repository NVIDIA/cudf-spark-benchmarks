SELECT 
    l_orderkey,
    COUNT(*) AS lineitem_count,
    SUM(l_extendedprice) AS total_extended_price,
    AVG(l_discount) AS average_discount,
    MAX(l_quantity) AS max_quantity
FROM 
    lineitem
WHERE 
    l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    l_orderkey
ORDER BY 
    total_extended_price DESC
LIMIT 100;