SELECT p_partkey, p_name, p_brand, p_retailprice
FROM part
WHERE p_retailprice > 100.00
ORDER BY p_retailprice DESC
LIMIT 10;
