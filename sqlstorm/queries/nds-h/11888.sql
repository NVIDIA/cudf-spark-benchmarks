SELECT 
    l_linenumber, 
    SUM(l_extendedprice) AS total_price, 
    AVG(l_discount) AS average_discount, 
    COUNT(*) AS line_item_count
FROM 
    lineitem 
WHERE 
    l_shipdate >= '1997-01-01' 
    AND l_shipdate < '1997-12-31' 
GROUP BY 
    l_linenumber 
ORDER BY 
    total_price DESC 
LIMIT 10;