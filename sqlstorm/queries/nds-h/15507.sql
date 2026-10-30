SELECT p_brand, AVG(p_retailprice) AS average_price 
FROM part 
GROUP BY p_brand 
ORDER BY average_price DESC;
