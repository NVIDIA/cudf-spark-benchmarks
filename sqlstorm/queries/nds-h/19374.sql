SELECT 
    p_brand, 
    COUNT(*) as number_of_parts, 
    AVG(p_retailprice) as average_price 
FROM 
    part 
GROUP BY 
    p_brand 
ORDER BY 
    number_of_parts DESC 
LIMIT 10;
