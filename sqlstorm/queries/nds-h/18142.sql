SELECT p_name, p_retailprice 
FROM part 
WHERE p_size > 15 
ORDER BY p_retailprice DESC 
LIMIT 10;
