SELECT p_brand, AVG(p_retailprice) AS avg_price 
FROM part 
GROUP BY p_brand 
ORDER BY avg_price DESC 
LIMIT 10;
