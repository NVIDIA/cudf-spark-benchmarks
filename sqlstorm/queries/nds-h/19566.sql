SELECT DISTINCT p_name, p_brand, p_retailprice
FROM part
WHERE p_size > 10
ORDER BY p_retailprice DESC
LIMIT 10;
