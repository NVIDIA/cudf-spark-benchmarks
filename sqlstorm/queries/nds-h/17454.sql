SELECT 
    p_brand, 
    COUNT(*) AS part_count, 
    AVG(p_retailprice) AS avg_retail_price 
FROM 
    part 
GROUP BY 
    p_brand 
HAVING 
    COUNT(*) > 10 
ORDER BY 
    avg_retail_price DESC;
